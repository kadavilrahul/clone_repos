#!/bin/bash

# -----------------------------------
# STEP 1: Install Required Tools
# -----------------------------------
echo "Checking and installing required tools..."

install_if_missing() {
  if ! command -v "$1" &>/dev/null; then
    echo "Installing $1..."
    sudo apt update && sudo apt install -y "$1"
  fi
}

install_if_missing git
install_if_missing bash
install_if_missing fzf
install_if_missing curl
install_if_missing jq

# -----------------------------------
# STEP 2: Configuration Management
# -----------------------------------

# Configuration file
CONFIG_FILE="config.json"

# Function to load configuration
load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    echo "Loading configuration from $CONFIG_FILE..."
    if command -v jq &>/dev/null; then
      DEFAULT_USERNAME=$(jq -r '.github.username // ""' "$CONFIG_FILE" 2>/dev/null)
      DEFAULT_TOKEN=$(jq -r '.github.token // ""' "$CONFIG_FILE" 2>/dev/null)
      DEFAULT_CLONE_PATH=$(jq -r '.clone.default_path // "./repos"' "$CONFIG_FILE" 2>/dev/null)
      
      # Load favorites and recent
      FAVORITES=($(jq -r '.favorites[]? // empty' "$CONFIG_FILE" 2>/dev/null))
      RECENT=($(jq -r '.recent[]? // empty' "$CONFIG_FILE" 2>/dev/null))
      
      # Load filter preferences
      SHOW_PRIVATE=$(jq -r '.filters.show_private // true' "$CONFIG_FILE" 2>/dev/null)
      SHOW_PUBLIC=$(jq -r '.filters.show_public // true' "$CONFIG_FILE" 2>/dev/null)
      EXCLUDE_FORKS=$(jq -r '.filters.exclude_forks // false' "$CONFIG_FILE" 2>/dev/null)
      FILTER_LANGUAGES=($(jq -r '.filters.languages[]? // empty' "$CONFIG_FILE" 2>/dev/null))
    else
      # Fallback parsing without jq
      DEFAULT_USERNAME=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
      DEFAULT_TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
      DEFAULT_CLONE_PATH=$(grep -o '"default_path"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"default_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "./repos")
      
      # Simple fallback for arrays (basic parsing)
      FAVORITES=()
      RECENT=()
      SHOW_PRIVATE=true
      SHOW_PUBLIC=true
      EXCLUDE_FORKS=false
      FILTER_LANGUAGES=()
    fi
  else
    # No config file exists - prompt for initial setup
    echo "No configuration file found. Setting up initial configuration..."
    DEFAULT_USERNAME=""
    DEFAULT_TOKEN=""
    DEFAULT_CLONE_PATH="./repos"
    FAVORITES=()
    RECENT=()
    SHOW_PRIVATE=true
    SHOW_PUBLIC=true
    EXCLUDE_FORKS=false
    FILTER_LANGUAGES=()
  fi
}

# Function to save configuration
save_config() {
  local username="$1"
  local token="$2"
  local clone_path="$3"
  
  echo "Saving configuration to $CONFIG_FILE..."
  
  # Convert arrays to JSON format
  local favorites_json=""
  if [ ${#FAVORITES[@]} -gt 0 ]; then
    favorites_json=$(printf '"%s",' "${FAVORITES[@]}")
    favorites_json="[${favorites_json%,}]"
  else
    favorites_json="[]"
  fi
  
  local recent_json=""
  if [ ${#RECENT[@]} -gt 0 ]; then
    recent_json=$(printf '"%s",' "${RECENT[@]}")
    recent_json="[${recent_json%,}]"
  else
    recent_json="[]"
  fi
  
  local languages_json=""
  if [ ${#FILTER_LANGUAGES[@]} -gt 0 ]; then
    languages_json=$(printf '"%s",' "${FILTER_LANGUAGES[@]}")
    languages_json="[${languages_json%,}]"
  else
    languages_json="[]"
  fi
  
  cat > "$CONFIG_FILE" << EOF
{
  "github": {
    "username": "$username",
    "token": "$token"
  },
  "clone": {
    "default_path": "$clone_path"
  },
  "favorites": $favorites_json,
  "recent": $recent_json,
  "filters": {
    "show_private": $SHOW_PRIVATE,
    "show_public": $SHOW_PUBLIC,
    "languages": $languages_json,
    "exclude_forks": $EXCLUDE_FORKS
  }
}
EOF
  echo "Configuration saved successfully!"
}

# Function to add to favorites
add_to_favorites() {
  local repo_name="$1"
  
  # Check if already in favorites
  for fav in "${FAVORITES[@]}"; do
    if [ "$fav" = "$repo_name" ]; then
      echo "Repository '$repo_name' is already in favorites."
      return
    fi
  done
  
  FAVORITES+=("$repo_name")
  echo "Added '$repo_name' to favorites."
}

# Function to remove from favorites
remove_from_favorites() {
  local repo_name="$1"
  local new_favorites=()
  
  for fav in "${FAVORITES[@]}"; do
    if [ "$fav" != "$repo_name" ]; then
      new_favorites+=("$fav")
    fi
  done
  
  FAVORITES=("${new_favorites[@]}")
  echo "Removed '$repo_name' from favorites."
}

# Function to add to recent
add_to_recent() {
  local repo_name="$1"
  local new_recent=("$repo_name")
  
  # Add existing recent items (excluding the current one to avoid duplicates)
  for recent in "${RECENT[@]}"; do
    if [ "$recent" != "$repo_name" ] && [ ${#new_recent[@]} -lt 10 ]; then
      new_recent+=("$recent")
    fi
  done
  
  RECENT=("${new_recent[@]}")
}

# Load configuration
load_config

# -----------------------------------
# STEP 3: GitHub API Functions
# -----------------------------------

# Function to fetch repositories from GitHub API
fetch_github_repos() {
  local username="$1"
  local token="$2"
  echo "Fetching repositories for user: $username..."
  
  # Prepare curl command with authentication if token is provided
  if [ -n "$token" ]; then
    echo "Using personal access token for authentication (includes private repos)..."
    # Use authenticated endpoint to get user's own repos (including private)
    api_url="https://api.github.com/user/repos?per_page=100&sort=name&affiliation=owner"
    api_response=$(curl -s -H "Authorization: token $token" "$api_url" 2>/dev/null)
  else
    echo "No token provided - only public repositories will be shown..."
    # Use public endpoint for user's public repos only
    api_url="https://api.github.com/users/$username/repos?per_page=100&sort=name"
    api_response=$(curl -s "$api_url" 2>/dev/null)
  fi
  
  if [ $? -ne 0 ] || [ -z "$api_response" ]; then
    echo "Failed to fetch repositories from GitHub API"
    return 1
  fi
  
  # Check if the response contains an error
  if echo "$api_response" | grep -q '"message".*"Not Found"'; then
    echo "User '$username' not found on GitHub"
    return 1
  fi
  
  # Parse JSON to extract repo names and clone URLs
  if command -v jq &>/dev/null; then
    echo "$api_response" | jq -r '.[] | "\(.name)|\(.clone_url)"'
  else
    # Fallback parsing without jq
    echo "$api_response" | grep -E '"name"|"clone_url"' | sed 'N;s/\n/ /' | \
      sed 's/.*"name": *"\([^"]*\)".*"clone_url": *"\([^"]*\)".*/\1|\2/'
  fi
  
  return 0
}

# Function to display repository info
show_repo_info() {
  local repo_name="$1"
  local repo_url="${REPO_LIST[$repo_name]}"
  
  echo ""
  echo "Repository: $repo_name"
  echo "URL: $repo_url"
  
  # Try to get additional info from GitHub API if token is available
  if [ -n "$token" ]; then
    local repo_info
    repo_info=$(curl -s -H "Authorization: token $token" "https://api.github.com/repos/$username/$repo_name" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$repo_info" ]; then
      if command -v jq &>/dev/null; then
        local description=$(echo "$repo_info" | jq -r '.description // "No description"')
        local language=$(echo "$repo_info" | jq -r '.language // "Unknown"')
        local private=$(echo "$repo_info" | jq -r '.private')
        local updated=$(echo "$repo_info" | jq -r '.updated_at' | cut -d'T' -f1)
        
        echo "Description: $description"
        echo "Language: $language"
        echo "Private: $private"
        echo "Last updated: $updated"
      fi
    fi
  fi
  echo ""
}

# -----------------------------------
# STEP 4: User Input and Authentication
# -----------------------------------

# Get GitHub username and token
if [ -n "$DEFAULT_USERNAME" ]; then
  read -p "Enter GitHub username (default: $DEFAULT_USERNAME): " input_username
  username="${input_username:-$DEFAULT_USERNAME}"
else
  echo "No username configured. Please enter your GitHub username."
  echo ""
  while [ -z "$username" ]; do
    read -p "Enter GitHub username (required): " username
    if [ -z "$username" ]; then
      echo "Username is required. Please try again."
    fi
  done
fi

echo ""
echo "GitHub Personal Access Token:"
if [ -n "$DEFAULT_TOKEN" ]; then
  echo "- Leave empty to use saved token"
  echo "- Enter 'none' for public repos only"
  echo "- Enter new token to override saved token"
  read -s -p "Enter GitHub token (default: use saved): " input_token
else
  echo "- Leave empty for public repos only"
  echo "- Enter token to access private repositories"
  read -s -p "Enter GitHub token (optional): " input_token
fi
echo ""

# Use provided token, or default token, or empty
if [ "$input_token" = "none" ]; then
  token=""
elif [ -n "$input_token" ]; then
  token="$input_token"
else
  token="$DEFAULT_TOKEN"
fi

# Ask if user wants to save new configuration
save_new_config=false
if [ "$username" != "$DEFAULT_USERNAME" ] || [ -n "$input_token" ] && [ "$input_token" != "none" ]; then
  read -p "Save this username/token to config? (y/n): " save_choice
  [[ "$save_choice" == "y" ]] && save_new_config=true
fi

# Force save if no config exists
if [ -z "$DEFAULT_USERNAME" ]; then
  save_new_config=true
  echo "Creating initial configuration..."
fi

# -----------------------------------
# STEP 5: Fetch Repositories
# -----------------------------------

# Fetch repositories
echo ""
repo_data=$(fetch_github_repos "$username" "$token")
if [ $? -ne 0 ]; then
  echo "Failed to fetch repositories. Exiting."
  exit 1
fi

# Parse repo data into arrays
declare -A REPO_LIST
REPO_NAMES=()

while IFS='|' read -r repo_name clone_url; do
  if [ -n "$repo_name" ] && [ -n "$clone_url" ]; then
    REPO_LIST["$repo_name"]="$clone_url"
    REPO_NAMES+=("$repo_name")
  fi
done <<< "$repo_data"

# Check if we got any repositories
if [ ${#REPO_NAMES[@]} -eq 0 ]; then
  echo "No repositories found for user '$username'. Exiting."
  exit 1
fi

# Sort repository names
IFS=$'\n' REPO_NAMES_SORTED=($(sort <<<"${REPO_NAMES[*]}"))
unset IFS

# -----------------------------------
# STEP 6: Repository Selection
# -----------------------------------

echo ""
echo "Repository Management"
echo "===================="
echo "Total repositories found: ${#REPO_NAMES_SORTED[@]}"
echo "Favorites: ${#FAVORITES[@]} | Recent: ${#RECENT[@]}"
echo ""
echo "Quick Access:"
if [ ${#FAVORITES[@]} -gt 0 ]; then
  echo "f) Show favorites (${#FAVORITES[@]} items)"
fi
if [ ${#RECENT[@]} -gt 0 ]; then
  echo "r) Show recent (${#RECENT[@]} items)"
fi
echo ""
echo "Repository Options:"
echo "1) Show all repositories"
echo "2) Filter repositories by name"
echo "b) Back to main menu"
echo ""

read -p "Choose option (1-2, f, r, b): " filter_choice

case "$filter_choice" in
  "f"|"F")
    if [ ${#FAVORITES[@]} -gt 0 ]; then
      echo ""
      echo "Favorite Repositories:"
      REPO_NAMES_SORTED=("${FAVORITES[@]}")
    else
      echo "No favorites saved yet."
      echo "Showing all repositories instead."
    fi
    ;;
  "r"|"R")
    if [ ${#RECENT[@]} -gt 0 ]; then
      echo ""
      echo "Recent Repositories:"
      REPO_NAMES_SORTED=("${RECENT[@]}")
    else
      echo "No recent repositories."
      echo "Showing all repositories instead."
    fi
    ;;
  "2")
    read -p "Enter filter term (partial name): " filter_term
    if [ -n "$filter_term" ]; then
      filtered_repos=()
      for repo in "${REPO_NAMES_SORTED[@]}"; do
        if [[ "$repo" == *"$filter_term"* ]]; then
          filtered_repos+=("$repo")
        fi
      done
      
      if [ ${#filtered_repos[@]} -eq 0 ]; then
        echo "No repositories found matching '$filter_term'. Showing all repositories."
      else
        echo "Found ${#filtered_repos[@]} repositories matching '$filter_term'"
        REPO_NAMES_SORTED=("${filtered_repos[@]}")
      fi
    fi
    ;;
  "b"|"B")
    echo "Returning to main menu..."
    exec bash "$0"
    ;;
  *)
    echo "Showing all repositories"
    ;;
esac

echo ""
echo "Available Repositories (${#REPO_NAMES_SORTED[@]} shown) - Choose a repository to clone:"
select selected_repo in "${REPO_NAMES_SORTED[@]}" "Back to menu"; do
  if [ "$selected_repo" = "Back to menu" ]; then
    echo "Returning to repository menu..."
    exec bash "$0"
  fi
  
  if [ -z "$selected_repo" ]; then
    echo "Invalid selection. Please try again."
    continue
  fi

  repo_url="${REPO_LIST[$selected_repo]}"

  # Add to recent repositories
  add_to_recent "$selected_repo"

  # Show repository info and ask about favorites
  echo ""
  echo "Selected repository: $selected_repo"
  show_repo_info "$selected_repo"

  # Check if already in favorites
  is_favorite=false
  for fav in "${FAVORITES[@]}"; do
    if [ "$fav" = "$selected_repo" ]; then
      is_favorite=true
      break
    fi
  done

  if [ "$is_favorite" = true ]; then
    read -p "Remove '$selected_repo' from favorites? (y/n): " remove_fav
    if [[ "$remove_fav" == "y" ]]; then
      remove_from_favorites "$selected_repo"
    fi
  else
    read -p "Add '$selected_repo' to favorites? (y/n): " add_fav
    if [[ "$add_fav" == "y" ]]; then
      add_to_favorites "$selected_repo"
    fi
  fi

  # -----------------------------------
  # STEP 7: Select Clone Location
  # -----------------------------------
  echo ""
  echo "Clone Location Selection"
  echo "======================="
  echo "Current default: $DEFAULT_CLONE_PATH"
  echo ""
  echo "1) Use default location ($DEFAULT_CLONE_PATH)"
  echo "2) Enter custom path"
  echo ""
  
  read -p "Choose option (1-2): " location_choice
  
  case "$location_choice" in
    "2")
      read -p "Enter custom clone path: " custom_path
      if [ -n "$custom_path" ]; then
        clone_path="$custom_path"
      else
        echo "No path entered. Using default."
        clone_path="$DEFAULT_CLONE_PATH"
      fi
      ;;
    *)
      clone_path="$DEFAULT_CLONE_PATH"
      ;;
  esac
  
  # Ask if user wants to save the new clone path as default
  if [ "$clone_path" != "$DEFAULT_CLONE_PATH" ]; then
    read -p "Save this path as default clone location? (y/n): " save_path_choice
    if [[ "$save_path_choice" == "y" ]]; then
      save_new_config=true
      DEFAULT_CLONE_PATH="$clone_path"
    fi
  fi
  
  # Save configuration if requested
  if [ "$save_new_config" = true ]; then
    save_config "$username" "$token" "$DEFAULT_CLONE_PATH"
  fi

  # -----------------------------------
  # STEP 8: Clone Repository
  # -----------------------------------
  echo ""
  echo "Cloning to: $clone_path"
  
  # Create and navigate to clone directory
  mkdir -p "$clone_path"
  cd "$clone_path" || { echo "Failed to access clone directory: $clone_path"; exit 1; }

  if [ -d "$selected_repo" ]; then
    echo "Directory '$selected_repo' already exists. Skipping clone."
  else
    echo "Cloning $selected_repo..."
    git clone "$repo_url"
  fi

  cd "$selected_repo" || { echo "Failed to cd into $selected_repo"; exit 1; }

  echo ""
  echo "Repository cloned successfully!"
  echo "Location: $(pwd)"
  break
done