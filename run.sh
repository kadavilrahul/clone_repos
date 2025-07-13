#!/bin/bash

# =============================================================================
# Repository Analysis Toolkit & Smart Clone System - Main Runner
# =============================================================================
# This script provides a user-friendly interface to install and use all tools
# 
# Features:
# - Smart Clone System installation
# - Repository analysis tools
# - Configuration management
# - Interactive menu system
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Functions for colored output
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
header() { echo -e "${WHITE}$1${NC}"; }
subheader() { echo -e "${CYAN}$1${NC}"; }

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in the right directory
check_directory() {
    if [[ ! -f "$SCRIPT_DIR/install_smart_clone.sh" ]] || [[ ! -f "$SCRIPT_DIR/report.sh" ]]; then
        error "Required files not found in $SCRIPT_DIR"
        error "Please run this script from the clone_repos directory"
        exit 1
    fi
}

# Display banner
show_banner() {
    clear
    echo -e "${PURPLE}🚀 Repository Analysis Toolkit & Smart Clone${NC}"
    echo -e "${WHITE}================================================${NC}"
}

# Check if config.json exists and create sample if needed
check_config_file() {
    if [[ ! -f "$SCRIPT_DIR/config.json" ]]; then
        warning "config.json not found!"
        echo ""
        info "A configuration file is required for GitHub integration."
        echo ""
        read -p "Would you like to create a configuration file now? (Y/n): " create_config
        
        if [[ "$create_config" =~ ^[Nn]$ ]]; then
            info "You can create config.json later using option 2 from the main menu"
            return 1
        else
            configure_github
            return 0
        fi
    fi
    return 0
}

# Check installation status
check_installation_status() {
    local status=""
    
    # Check if smart clone is installed
    if [[ -f "$HOME/.bashrc" ]] && grep -q "clone_helper.sh" "$HOME/.bashrc" 2>/dev/null; then
        status="${GREEN}✅ Smart Clone System: Installed${NC}"
    else
        status="${RED}❌ Smart Clone System: Not Installed${NC}"
    fi
    
    echo -e "$status"
    
    # Check if config exists
    if [[ -f "$SCRIPT_DIR/config.json" ]]; then
        local username=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/config.json" 2>/dev/null | sed 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
        if [[ -n "$username" ]] && [[ "$username" != "your_github_username" ]]; then
            echo -e "${GREEN}✅ GitHub Configuration: Configured (User: $username)${NC}"
        else
            echo -e "${YELLOW}⚠️  GitHub Configuration: Incomplete or using sample values${NC}"
        fi
    else
        echo -e "${RED}❌ GitHub Configuration: Not Found${NC}"
    fi
    
    echo ""
}

# Install smart clone system
install_smart_clone() {
    header "Installing Smart Clone System"
    echo "=============================="
    echo ""
    
    if [[ -f "$SCRIPT_DIR/install_smart_clone.sh" ]]; then
        chmod +x "$SCRIPT_DIR/install_smart_clone.sh"
        info "Running smart clone installer..."
        echo ""
        bash "$SCRIPT_DIR/install_smart_clone.sh"
        echo ""
        success "Smart clone installation completed!"
    else
        error "install_smart_clone.sh not found!"
        return 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Configure GitHub credentials
configure_github() {
    header "GitHub Configuration"
    echo "===================="
    echo ""
    
    # Check if sample config exists and offer to copy it
    if [[ -f "$SCRIPT_DIR/sample_config.json" ]] && [[ ! -f "$SCRIPT_DIR/config.json" ]]; then
        info "Found sample_config.json template"
        echo ""
        read -p "Would you like to copy sample_config.json to config.json and edit it? (Y/n): " use_sample
        
        if [[ ! "$use_sample" =~ ^[Nn]$ ]]; then
            cp "$SCRIPT_DIR/sample_config.json" "$SCRIPT_DIR/config.json"
            chmod 600 "$SCRIPT_DIR/config.json"
            info "Copied sample_config.json to config.json"
            echo ""
        fi
    fi
    
    info "Setting up GitHub credentials for repository access"
    echo ""
    
    # Show current config if it exists
    if [[ -f "$SCRIPT_DIR/config.json" ]]; then
        local current_username=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/config.json" 2>/dev/null | sed 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
        if [[ -n "$current_username" ]] && [[ "$current_username" != "your_github_username" ]]; then
            info "Current username: $current_username"
            read -p "Keep current username? (Y/n): " keep_username
            if [[ ! "$keep_username" =~ ^[Nn]$ ]]; then
                github_username="$current_username"
            else
                read -p "Enter your GitHub username: " github_username
            fi
        else
            read -p "Enter your GitHub username: " github_username
        fi
    else
        read -p "Enter your GitHub username: " github_username
    fi
    
    echo ""
    echo "GitHub Personal Access Token:"
    echo "- Create at: https://github.com/settings/tokens"
    echo "- Required scopes: 'repo' (for private repos) or 'public_repo' (for public only)"
    echo "- Leave empty to skip (public repos only)"
    echo ""
    read -s -p "Enter GitHub token (optional): " github_token
    echo ""
    echo ""
    
    # Create or update config file
    cat > "$SCRIPT_DIR/config.json" << EOF
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
EOF
    
    # Set secure permissions
    chmod 600 "$SCRIPT_DIR/config.json"
    
    success "GitHub configuration saved!"
    warning "Config file permissions set to 600 for security"
    echo ""
    read -p "Press Enter to continue..."
}

# Run repository analysis
run_analysis() {
    header "Repository Analysis"
    echo "==================="
    echo ""
    
    if [[ ! -f "$SCRIPT_DIR/report.sh" ]]; then
        error "report.sh not found!"
        return 1
    fi
    
    echo "Choose analysis type:"
    echo "1) Analyze current directory"
    echo "2) Analyze specific directory"
    echo "3) Interactive mode (choose options)"
    echo ""
    read -p "Enter choice (1-3): " analysis_choice
    
    case $analysis_choice in
        1)
            info "Analyzing current directory: $(pwd)"
            bash "$SCRIPT_DIR/report.sh" "$(pwd)"
            ;;
        2)
            read -p "Enter directory path to analyze: " target_dir
            if [[ -d "$target_dir" ]]; then
                info "Analyzing directory: $target_dir"
                bash "$SCRIPT_DIR/report.sh" "$target_dir"
            else
                error "Directory not found: $target_dir"
            fi
            ;;
        3)
            info "Starting interactive analysis mode"
            bash "$SCRIPT_DIR/report.sh"
            ;;
        *)
            error "Invalid choice"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Run codebase comparison
run_comparison() {
    header "Codebase Comparison"
    echo "==================="
    echo ""
    
    if [[ ! -f "$SCRIPT_DIR/compare_lines_of_code.sh" ]]; then
        error "compare_lines_of_code.sh not found!"
        return 1
    fi
    
    info "Starting codebase comparison (current directory will be analyzed first)"
    echo ""
    bash "$SCRIPT_DIR/compare_lines_of_code.sh"
    
    echo ""
    read -p "Press Enter to continue..."
}

# Test smart clone functionality
test_smart_clone() {
    header "Test Smart Clone System"
    echo "======================="
    echo ""
    
    # Check if clone function is available
    if command -v clone &> /dev/null || type clone &> /dev/null; then
        success "Smart clone command is available!"
        echo ""
        info "Testing clone command help..."
        echo ""
        
        # Source the helper if needed
        if [[ -f "$SCRIPT_DIR/.clone_helper.sh" ]]; then
            source "$SCRIPT_DIR/.clone_helper.sh"
        fi
        
        # Test the clone function
        clone 2>/dev/null || echo "Clone function loaded successfully"
        
        echo ""
        info "Available tab completion keywords:"
        echo "email, html, css, javascript, python, nodejs, go, api, web, app, bot, tool, script, automation"
        echo "wordpress, woocommerce, generate, import, install, config, setup, test, demo, template"
        echo ""
        info "Example usage:"
        echo "  clone email      # Find email-related repositories"
        echo "  clone html       # Find HTML/web repositories"
        echo "  clone python     # Find Python repositories"
        
    else
        warning "Smart clone command not found!"
        echo ""
        info "To activate smart clone, run:"
        echo "  source ~/.bashrc"
        echo "  # or open a new terminal"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# View system status and logs
view_status() {
    header "System Status & Information"
    echo "==========================="
    echo ""
    
    subheader "Installation Status:"
    check_installation_status
    
    subheader "File Structure:"
    echo "📁 $SCRIPT_DIR/"
    ls -la "$SCRIPT_DIR" | grep -E '\.(sh|json|md)$' | awk '{print "   " $9 " (" $5 " bytes)"}'
    echo ""
    
    subheader "Recent Output Files:"
    if [[ -f "$SCRIPT_DIR/codebase_line_counts.txt" ]]; then
        echo "📊 codebase_line_counts.txt ($(stat -c%s "$SCRIPT_DIR/codebase_line_counts.txt" 2>/dev/null || echo "unknown") bytes)"
    fi
    
    if [[ -d "$SCRIPT_DIR/reports" ]]; then
        local report_count=$(find "$SCRIPT_DIR/reports" -name "*.md" 2>/dev/null | wc -l)
        echo "📋 reports/ directory ($report_count report files)"
    fi
    echo ""
    
    subheader "Dependencies Status:"
    local deps=("git" "curl" "jq" "tree" "cloc" "fzf")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo -e "   ${GREEN}✅ $dep${NC}"
        else
            echo -e "   ${RED}❌ $dep${NC} (optional)"
        fi
    done
    
    echo ""
    read -p "Press Enter to continue..."
}

# Uninstall smart clone system
uninstall_system() {
    header "Uninstall Smart Clone System"
    echo "============================"
    echo ""
    
    warning "This will remove the smart clone system from your shell configuration"
    echo ""
    read -p "Are you sure you want to uninstall? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        info "Removing smart clone system..."
        
        # Remove from bashrc
        if [[ -f "$HOME/.bashrc" ]]; then
            sed -i '/clone_helper/d' "$HOME/.bashrc" 2>/dev/null || true
            sed -i '/Smart clone command/d' "$HOME/.bashrc" 2>/dev/null || true
        fi
        
        # Remove from zshrc
        if [[ -f "$HOME/.zshrc" ]]; then
            sed -i '/clone_helper/d' "$HOME/.zshrc" 2>/dev/null || true
            sed -i '/Smart clone command/d' "$HOME/.zshrc" 2>/dev/null || true
        fi
        
        success "Smart clone system removed from shell configuration"
        info "You may need to restart your terminal or run: source ~/.bashrc"
        
    else
        info "Uninstall cancelled"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Show help and documentation
show_help() {
    header "Help & Documentation"
    echo "===================="
    echo ""
    
    subheader "Available Scripts:"
    echo "📜 run.sh                    - This main control panel"
    echo "🚀 install_smart_clone.sh   - Install smart clone system"
    echo "📊 report.sh                - Comprehensive project analysis"
    echo "📈 compare_lines_of_code.sh - Multi-codebase comparison"
    echo "⚙️  clone.sh                 - Advanced GitHub repository management"
    echo ""
    
    subheader "Smart Clone Commands:"
    echo "🔍 clone <keyword>     - Clone repositories by keyword"
    echo "📋 clone <TAB>         - Show available keywords"
    echo ""
    
    subheader "Configuration Files:"
    echo "⚙️  config.json        - GitHub credentials and settings"
    echo "📖 README.md          - Complete documentation"
    echo ""
    
    subheader "Quick Start:"
    echo "1. Install smart clone system (option 1)"
    echo "2. Configure GitHub credentials (option 2)"
    echo "3. Test the system (option 6)"
    echo "4. Use 'clone <keyword>' to clone repositories"
    echo ""
    
    subheader "Documentation:"
    if [[ -f "$SCRIPT_DIR/README.md" ]]; then
        echo "📖 Full documentation available in README.md"
        read -p "Would you like to view the README? (y/N): " view_readme
        if [[ "$view_readme" =~ ^[Yy]$ ]]; then
            if command -v less &> /dev/null; then
                less "$SCRIPT_DIR/README.md"
            else
                cat "$SCRIPT_DIR/README.md"
            fi
        fi
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu
show_menu() {
    show_banner
    check_installation_status
    
    echo -e "${WHITE}Main Menu:${NC}"
    echo "1) Install Smart Clone System    - Set up keyword-based git cloning"
    echo "2) Configure GitHub Credentials  - Add username and access token"
    echo "3) Repository Analysis          - Analyze code structure and stats"
    echo "4) Codebase Comparison          - Compare multiple project sizes"
    echo "5) System Status                - Check installation and dependencies"
    echo "6) Test Smart Clone             - Verify clone command functionality"
    echo "7) Uninstall System             - Remove smart clone from shell"
    echo "8) Help & Documentation         - View guides and examples"
    echo "0) Exit                         - Quit the program"
    echo ""
}

# Main loop
main() {
    # Check if we're in the right directory
    check_directory
    
    # Check config file on first run
    check_config_file
    
    while true; do
        show_menu
        read -p "Enter choice (0-8): " choice
        echo ""
        
        case $choice in
            1) install_smart_clone ;;
            2) configure_github ;;
            3) run_analysis ;;
            4) run_comparison ;;
            5) view_status ;;
            6) test_smart_clone ;;
            7) uninstall_system ;;
            8) show_help ;;
            0) 
                success "Thank you for using Repository Analysis Toolkit!"
                exit 0
                ;;
            *)
                error "Invalid choice. Please enter 0-8."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function
main "$@"