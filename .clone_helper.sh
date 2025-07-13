#!/bin/bash

# Smart clone helper with fuzzy search and tab completion
# Usage: clone <keyword> - searches and clones repos containing the keyword

clone() {
    local keyword="$1"
    local config_file="/root/clone_repos/config.json"
    
    # Check if keyword provided
    if [ -z "$keyword" ]; then
        echo "Usage: clone <keyword>"
        echo "Example: clone email    (finds email_automation_private, etc.)"
        echo "Example: clone html     (finds generate_html_from_csv, etc.)"
        return 1
    fi
    
    # Check if config exists
    if [ ! -f "$config_file" ]; then
        echo "Config file not found. Please run the clone_repos setup first."
        return 1
    fi
    
    # Extract username and token from config
    local username=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    local token=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    
    if [ -z "$username" ]; then
        echo "GitHub username not found in config. Please run clone_repos setup first."
        return 1
    fi
    
    echo "Searching repos for keyword: $keyword"
    echo "GitHub user: $username"
    
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
        echo "Failed to fetch repositories from GitHub API"
        return 1
    fi
    
    # Extract repos matching the keyword
    local matching_repos=()
    local repo_urls=()
    
    # Parse JSON and find matches (simple grep-based approach)
    while IFS= read -r line; do
        if echo "$line" | grep -q '"name"'; then
            local repo_name=$(echo "$line" | sed 's/.*"name": *"\([^"]*\)".*/\1/')
            # Check if repo name contains the keyword (case insensitive)
            if echo "$repo_name" | grep -qi "$keyword"; then
                matching_repos+=("$repo_name")
            fi
        fi
    done <<< "$api_response"
    
    # If no matches found, try fuzzy search
    if [ ${#matching_repos[@]} -eq 0 ]; then
        echo "No exact matches found. Trying fuzzy search..."
        while IFS= read -r line; do
            if echo "$line" | grep -q '"name"'; then
                local repo_name=$(echo "$line" | sed 's/.*"name": *"\([^"]*\)".*/\1/')
                # Split keyword and check if any part matches
                for word in $(echo "$keyword" | tr '_-' ' '); do
                    if echo "$repo_name" | grep -qi "$word"; then
                        matching_repos+=("$repo_name")
                        break
                    fi
                done
            fi
        done <<< "$api_response"
    fi
    
    if [ ${#matching_repos[@]} -eq 0 ]; then
        echo "No repositories found matching '$keyword'"
        echo "Available repos:"
        echo "$api_response" | grep '"name"' | sed 's/.*"name": *"\([^"]*\)".*/  \1/' | head -10
        return 1
    fi
    
    # If exactly one match, clone it directly
    if [ ${#matching_repos[@]} -eq 1 ]; then
        local selected_repo="${matching_repos[0]}"
        echo "Found exact match: $selected_repo"
    else
        # Multiple matches - let user choose
        echo "Multiple matches found:"
        for i in "${!matching_repos[@]}"; do
            echo "$((i+1))) ${matching_repos[i]}"
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
            echo "Invalid selection"
            return 1
        fi
    fi
    
    # Get the clone URL for the selected repo
    local clone_url="https://github.com/$username/$selected_repo.git"
    
    echo ""
    echo "Cloning: $selected_repo"
    echo "URL: $clone_url"
    echo "Target: $(pwd)/$selected_repo"
    echo ""
    
    # Clone the repository
    if [ -d "$selected_repo" ]; then
        echo "Directory '$selected_repo' already exists!"
        read -p "Enter existing directory anyway? (y/n): " enter_choice
        if [[ "$enter_choice" == "y" ]]; then
            cd "$selected_repo"
            echo "Entered: $(pwd)"
        fi
    else
        if git clone "$clone_url"; then
            cd "$selected_repo"
            echo ""
            echo "✅ Successfully cloned and entered: $(pwd)"
            
            # Show basic repo info
            if [ -f "README.md" ]; then
                echo ""
                echo "📖 README found:"
                head -5 README.md | sed 's/^/  /'
                echo "  ..."
            fi
            
            # Show recent commits
            echo ""
            echo "📝 Recent commits:"
            git log --oneline -3 | sed 's/^/  /'
            
        else
            echo "❌ Failed to clone repository"
            return 1
        fi
    fi
}

# Tab completion for clone command
_clone_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local config_file="/root/clone_repos/config.json"
    
    if [ ! -f "$config_file" ]; then
        return 0
    fi
    
    # Extract common keywords from repo names
    local keywords=(
        "email" "html" "csv" "wordpress" "woocommerce" "automation" 
        "generate" "import" "install" "migration" "backup" "clone"
        "useful" "commands" "agent" "streamlit" "python" "nodejs" "go"
    )
    
    # Generate completions
    COMPREPLY=($(compgen -W "${keywords[*]}" -- "$cur"))
}

# Register completion
complete -F _clone_completion clone