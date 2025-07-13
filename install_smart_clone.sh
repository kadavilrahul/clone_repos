#!/bin/bash

# =============================================================================
# Smart Clone Command Installer
# =============================================================================
# This script installs the smart clone command with fuzzy search and tab completion
# 
# Features:
# - Clone repos using keywords (e.g., clone email, clone html)
# - Tab completion for common keywords
# - Clones to current directory and auto-enters folder
# - Shows repo info after cloning
# - Handles multiple matches with interactive selection
#
# Usage: curl -s https://raw.githubusercontent.com/username/repo/main/install_smart_clone.sh | bash
# Or: ./install_smart_clone.sh
# =============================================================================

set -e  # Exit on any error

echo "🚀 Smart Clone Command Installer"
echo "================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions for colored output
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Check if running as root (optional warning)
if [ "$EUID" -eq 0 ]; then
    warning "Running as root. The installation will be system-wide."
    sleep 2
fi

# Detect user's home directory
if [ "$EUID" -eq 0 ]; then
    # If root, ask for target user or use root
    read -p "Install for which user? (default: root): " target_user
    target_user="${target_user:-root}"
    if [ "$target_user" = "root" ]; then
        USER_HOME="/root"
    else
        USER_HOME="/home/$target_user"
    fi
else
    USER_HOME="$HOME"
    target_user="$(whoami)"
fi

info "Installing for user: $target_user"
info "Home directory: $USER_HOME"

# Step 1: Install required dependencies
echo ""
info "Step 1: Installing required dependencies..."

install_if_missing() {
    if ! command -v "$1" &>/dev/null; then
        info "Installing $1..."
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y "$1"
        elif command -v yum &>/dev/null; then
            sudo yum install -y "$1"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "$1"
        else
            error "Package manager not found. Please install $1 manually."
            exit 1
        fi
    else
        success "$1 is already installed"
    fi
}

# Install core dependencies
install_if_missing git
install_if_missing curl
install_if_missing bash

# Optional: Install jq for better JSON parsing
if ! command -v jq &>/dev/null; then
    warning "jq not found. Installing for better JSON parsing..."
    install_if_missing jq
else
    success "jq is already installed"
fi

# Step 2: Create the smart clone helper script
echo ""
info "Step 2: Creating smart clone helper script..."

CLONE_HELPER_PATH="$USER_HOME/.clone_helper.sh"

cat > "$CLONE_HELPER_PATH" << 'EOF'
#!/bin/bash

# Smart clone helper with fuzzy search and tab completion
# Usage: clone <keyword> - searches and clones repos containing the keyword

clone() {
    local keyword="$1"
    local config_file="$HOME/.github_clone_config.json"
    
    # Check if keyword provided
    if [ -z "$keyword" ]; then
        echo "Usage: clone <keyword>"
        echo "Example: clone email    (finds email_automation_private, etc.)"
        echo "Example: clone html     (finds generate_html_from_csv, etc.)"
        echo ""
        echo "💡 Tip: Use TAB completion for keyword suggestions"
        return 1
    fi
    
    # Check if config exists
    if [ ! -f "$config_file" ]; then
        echo "⚙️  GitHub configuration not found. Let's set it up!"
        echo ""
        read -p "Enter your GitHub username: " github_username
        echo ""
        echo "GitHub Personal Access Token (optional but recommended):"
        echo "- Leave empty for public repos only"
        echo "- Create token at: https://github.com/settings/tokens"
        echo "- Required scopes: repo (for private repos)"
        read -s -p "Enter GitHub token (optional): " github_token
        echo ""
        
        # Create config file
        cat > "$config_file" << CONFIGEOF
{
  "github": {
    "username": "$github_username",
    "token": "$github_token"
  },
  "clone": {
    "default_path": "."
  },
  "favorites": [],
  "recent": [],
  "filters": {
    "show_private": true,
    "show_public": true,
    "languages": [],
    "exclude_forks": false
  }
}
CONFIGEOF
        echo "✅ Configuration saved to $config_file"
        echo ""
    fi
    
    # Extract username and token from config
    local username token
    if command -v jq &>/dev/null; then
        username=$(jq -r '.github.username // ""' "$config_file")
        token=$(jq -r '.github.token // ""' "$config_file")
    else
        # Fallback parsing without jq
        username=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        token=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    if [ -z "$username" ]; then
        echo "❌ GitHub username not found in config. Please run 'clone' without arguments to reconfigure."
        return 1
    fi
    
    echo "🔍 Searching repos for keyword: $keyword"
    echo "👤 GitHub user: $username"
    
    # Fetch repos from GitHub API
    local api_url="https://api.github.com/user/repos?per_page=100&sort=name&affiliation=owner"
    local api_response
    
    if [ -n "$token" ]; then
        api_response=$(curl -s -H "Authorization: token $token" "$api_url" 2>/dev/null)
    else
        api_url="https://api.github.com/users/$username/repos?per_page=100&sort=name"
        api_response=$(curl -s "$api_url" 2>/dev/null)
    fi
    
    if [ $? -ne 0 ] || [ -z "$api_response" ]; then
        echo "❌ Failed to fetch repositories from GitHub API"
        return 1
    fi
    
    # Check for API errors
    if echo "$api_response" | grep -q '"message".*"Not Found"'; then
        echo "❌ User '$username' not found on GitHub"
        return 1
    fi
    
    if echo "$api_response" | grep -q '"message".*"Bad credentials"'; then
        echo "❌ Invalid GitHub token. Please reconfigure."
        return 1
    fi
    
    # Extract repos matching the keyword
    local matching_repos=()
    
    # Parse JSON and find matches (case insensitive)
    if command -v jq &>/dev/null; then
        while IFS= read -r repo_name; do
            if echo "$repo_name" | grep -qi "$keyword"; then
                matching_repos+=("$repo_name")
            fi
        done < <(echo "$api_response" | jq -r '.[].name')
    else
        # Fallback parsing without jq
        while IFS= read -r line; do
            if echo "$line" | grep -q '"name"'; then
                local repo_name=$(echo "$line" | sed 's/.*"name": *"\([^"]*\)".*/\1/')
                if echo "$repo_name" | grep -qi "$keyword"; then
                    matching_repos+=("$repo_name")
                fi
            fi
        done <<< "$api_response"
    fi
    
    # If no exact matches found, try fuzzy search
    if [ ${#matching_repos[@]} -eq 0 ]; then
        echo "🔍 No exact matches found. Trying fuzzy search..."
        if command -v jq &>/dev/null; then
            while IFS= read -r repo_name; do
                # Split keyword and check if any part matches
                for word in $(echo "$keyword" | tr '_-' ' '); do
                    if echo "$repo_name" | grep -qi "$word"; then
                        matching_repos+=("$repo_name")
                        break
                    fi
                done
            done < <(echo "$api_response" | jq -r '.[].name')
        else
            # Fallback fuzzy search
            while IFS= read -r line; do
                if echo "$line" | grep -q '"name"'; then
                    local repo_name=$(echo "$line" | sed 's/.*"name": *"\([^"]*\)".*/\1/')
                    for word in $(echo "$keyword" | tr '_-' ' '); do
                        if echo "$repo_name" | grep -qi "$word"; then
                            matching_repos+=("$repo_name")
                            break
                        fi
                    done
                fi
            done <<< "$api_response"
        fi
    fi
    
    if [ ${#matching_repos[@]} -eq 0 ]; then
        echo "❌ No repositories found matching '$keyword'"
        echo ""
        echo "📋 Available repos (first 10):"
        if command -v jq &>/dev/null; then
            echo "$api_response" | jq -r '.[].name' | head -10 | sed 's/^/  /'
        else
            echo "$api_response" | grep '"name"' | sed 's/.*"name": *"\([^"]*\)".*/  \1/' | head -10
        fi
        return 1
    fi
    
    # If exactly one match, clone it directly
    if [ ${#matching_repos[@]} -eq 1 ]; then
        local selected_repo="${matching_repos[0]}"
        echo "🎯 Found exact match: $selected_repo"
    else
        # Multiple matches - let user choose
        echo ""
        echo "📋 Multiple matches found:"
        for i in "${!matching_repos[@]}"; do
            echo "  $((i+1))) ${matching_repos[i]}"
        done
        echo ""
        read -p "Select repository (1-${#matching_repos[@]}) or press Enter for first: " choice
        
        # Default to first option if no input
        if [ -z "$choice" ]; then
            choice=1
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#matching_repos[@]}" ]; then
            local selected_repo="${matching_repos[$((choice-1))]}"
        else
            echo "❌ Invalid selection"
            return 1
        fi
    fi
    
    # Get the clone URL for the selected repo
    local clone_url="https://github.com/$username/$selected_repo.git"
    
    echo ""
    echo "📦 Cloning: $selected_repo"
    echo "🔗 URL: $clone_url"
    echo "📍 Target: $(pwd)/$selected_repo"
    echo ""
    
    # Clone the repository
    if [ -d "$selected_repo" ]; then
        echo "⚠️  Directory '$selected_repo' already exists!"
        read -p "Enter existing directory anyway? (y/n): " enter_choice
        if [[ "$enter_choice" == "y" ]]; then
            cd "$selected_repo"
            echo "📂 Entered: $(pwd)"
        fi
    else
        if git clone "$clone_url"; then
            cd "$selected_repo"
            echo ""
            echo "✅ Successfully cloned and entered: $(pwd)"
            
            # Show basic repo info
            if [ -f "README.md" ]; then
                echo ""
                echo "📖 README preview:"
                head -5 README.md | sed 's/^/  /'
                if [ $(wc -l < README.md) -gt 5 ]; then
                    echo "  ..."
                fi
            fi
            
            # Show recent commits
            echo ""
            echo "📝 Recent commits:"
            git log --oneline -3 2>/dev/null | sed 's/^/  /' || echo "  No commits found"
            
        else
            echo "❌ Failed to clone repository"
            return 1
        fi
    fi
}

# Tab completion for clone command
_clone_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    
    # Common keywords based on typical repository patterns
    local keywords=(
        "email" "html" "csv" "wordpress" "woocommerce" "automation" 
        "generate" "import" "install" "migration" "backup" "clone"
        "useful" "commands" "agent" "streamlit" "python" "nodejs" "go"
        "api" "web" "app" "bot" "tool" "script" "config" "setup"
        "test" "demo" "example" "template" "starter" "boilerplate"
        "admin" "dashboard" "frontend" "backend" "database" "auth"
        "docker" "kubernetes" "aws" "deploy" "ci" "cd" "monitor"
    )
    
    # Generate completions
    COMPREPLY=($(compgen -W "${keywords[*]}" -- "$cur"))
}

# Register completion
complete -F _clone_completion clone
EOF

success "Created smart clone helper at $CLONE_HELPER_PATH"

# Step 3: Add to shell configuration
echo ""
info "Step 3: Adding to shell configuration..."

# Detect shell and add to appropriate config file
SHELL_CONFIG=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$USER_HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$USER_HOME/.zshrc"
else
    # Default to bashrc
    SHELL_CONFIG="$USER_HOME/.bashrc"
fi

# Check if already added
if grep -q "clone_helper.sh" "$SHELL_CONFIG" 2>/dev/null; then
    warning "Smart clone already configured in $SHELL_CONFIG"
else
    echo "" >> "$SHELL_CONFIG"
    echo "# Smart clone command with fuzzy search" >> "$SHELL_CONFIG"
    echo "source $CLONE_HELPER_PATH" >> "$SHELL_CONFIG"
    echo "" >> "$SHELL_CONFIG"
    success "Added to $SHELL_CONFIG"
fi

# Step 4: Add clear alias if not exists
echo ""
info "Step 4: Adding convenient aliases..."

if ! grep -q "alias c='clear'" "$SHELL_CONFIG" 2>/dev/null; then
    echo "# Quick clear alias" >> "$SHELL_CONFIG"
    echo "alias c='clear'" >> "$SHELL_CONFIG"
    success "Added 'c' alias for clear command"
else
    warning "'c' alias already exists"
fi

# Step 5: Make scripts executable
chmod +x "$CLONE_HELPER_PATH"
success "Made scripts executable"

# Step 6: Source the configuration
echo ""
info "Step 6: Activating configuration..."

# Source the helper script directly for immediate use
source "$CLONE_HELPER_PATH"
success "Smart clone command is now available!"

# Final instructions
echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "✅ The 'clone' command is now ready to use!"
echo ""
echo "📚 Usage examples:"
echo "  clone email      # Finds email-related repos"
echo "  clone html       # Finds HTML/web repos"  
echo "  clone wordpress  # Finds WordPress repos"
echo "  clone api        # Finds API repos"
echo ""
echo "💡 Features:"
echo "  • Fuzzy search by repository keywords"
echo "  • Tab completion (try: clone <TAB>)"
echo "  • Clones to current directory"
echo "  • Automatically enters the folder"
echo "  • Shows repo info after cloning"
echo ""
echo "⚙️  Configuration:"
echo "  • Config file: $USER_HOME/.github_clone_config.json"
echo "  • Shell config: $SHELL_CONFIG"
echo "  • Helper script: $CLONE_HELPER_PATH"
echo ""
echo "🔄 To use immediately: source $SHELL_CONFIG"
echo "   Or open a new terminal session"
echo ""

# Offer to configure GitHub credentials now
if [ ! -f "$USER_HOME/.github_clone_config.json" ]; then
    echo ""
    read -p "Would you like to configure GitHub credentials now? (y/n): " configure_now
    if [[ "$configure_now" == "y" ]]; then
        echo ""
        info "Running first-time setup..."
        clone --help >/dev/null 2>&1 || true  # This will trigger the config setup
    fi
fi

echo ""
success "Enjoy your new smart clone command! 🚀"