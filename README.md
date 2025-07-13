# Repository Analysis Toolkit & Smart Clone System

A comprehensive collection of bash scripts for analyzing, comparing, and managing code repositories with an intelligent cloning system that uses fuzzy search and tab completion.

## 🚀 Quick Start

### Basic Usage
```bash
# Clone repositories using keywords (Smart Clone System)
clone email      # Finds: email_automation_private, setup_email_system, etc.
clone html       # Finds: generate_html_from_csv, etc.
clone wordpress  # Finds: install_wordpress_on_lamp, etc.
clone api        # Finds: api-related repositories

# Use tab completion for suggestions
clone <TAB>      # Shows available keywords

# Run interactive analysis
bash report.sh

# Compare multiple codebases
bash compare.sh

# Advanced cloning with GitHub integration
bash clone.sh
```

### Installation

#### Clone from GitHub

```bash
git clone https://github.com/kadavilrahul/clone_repos.git && cd clone_repos

```bash
bash install_smart_clone.sh
```

## 📋 Table of Contents

1. [Scripts Overview](#scripts-overview)
2. [Smart Clone System](#smart-clone-system)
3. [Installation Guide](#installation-guide)
4. [Configuration](#configuration)
5. [Security](#security)
6. [Use Cases & Examples](#use-cases--examples)
7. [Dependencies](#dependencies)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Usage](#advanced-usage)
10. [Recommendations & Future Enhancements](#recommendations--future-enhancements)

## 📋 Scripts Overview

### 🔍 `report.sh` - Comprehensive Project Analysis
**The flagship analysis tool** with interactive navigation and detailed reporting.

**Features:**
- 📊 Project structure visualization
- 🔒 Security pattern scanning
- 📈 Code statistics by language
- 🔍 Function extraction
- 📝 Git repository statistics
- 🎨 Colorized terminal output
- 📁 Auto-opens report folder

**Usage:**
```bash
# Interactive mode
./report.sh

# Direct analysis
./report.sh /path/to/project

# Generate report
./report.sh /path/to/project report

# Search for patterns
./report.sh /path/to/project search "API_KEY"

# Extract functions
./report.sh /path/to/project functions

# Git statistics
./report.sh /path/to/project git
```

### 📊 `compare.sh` - Multi-Codebase Comparison
**Compare multiple projects** with detailed statistics and analysis.

**Features:**
- Line count comparisons across projects
- File type distribution analysis
- Size and complexity metrics
- Batch processing capabilities
- Export results to files

**Usage:**
```bash
# Interactive comparison
./compare.sh

# Results saved to codebase_line_counts.txt
```

### 🚀 `clone.sh` - Advanced GitHub Repository Management
**Comprehensive GitHub integration** with filtering and management features.

**Features:**
- GitHub API integration
- Repository filtering by language, type, visibility
- Favorites management
- Recent repositories tracking
- Batch cloning capabilities
- Interactive repository browser

**Usage:**
```bash
# Interactive GitHub browser
./clone.sh

# Configure GitHub credentials in config.json
```

### ⚡ Smart Clone Command (`clone`)
**Intelligent keyword-based cloning** with fuzzy search and tab completion.

**Features:**
- Fuzzy search by repository keywords
- Tab completion for common terms
- Clones to current directory
- Automatically enters the folder
- Shows repo info after cloning
- Handles multiple matches with interactive selection

## 🔍 Smart Clone System

### How It Works

The smart clone system creates an intelligent `clone` command that:

1. **Searches** your GitHub repositories using the GitHub API
2. **Matches** repository names against your keyword using fuzzy search
3. **Presents** multiple matches for interactive selection
4. **Clones** the selected repository to your current directory
5. **Enters** the cloned directory automatically
6. **Shows** repository information, README preview, and recent commits

### Usage Examples

```bash
# Clone repositories using keywords
clone email      # Finds email_automation_private, etc.
clone html       # Finds generate_html_from_csv, etc.
clone wordpress  # Finds install_wordpress_on_lamp, etc.
clone api        # Finds api-related repositories
clone bot        # Finds bot and automation repos

# Use tab completion for suggestions
clone <TAB>      # Shows available keywords

# The command will:
# 1. Search your GitHub repos for the keyword
# 2. Show matches (if multiple found)
# 3. Clone to current directory
# 4. Enter the cloned folder
# 5. Show README preview and recent commits
```

### Tab Completion Keywords

Available keywords for tab completion:
- **Languages**: `python`, `nodejs`, `go`, `html`, `css`, `javascript`
- **Functions**: `api`, `web`, `app`, `bot`, `tool`, `script`, `automation`
- **Types**: `email`, `wordpress`, `woocommerce`, `generate`, `import`, `install`
- **Development**: `config`, `setup`, `test`, `demo`, `template`, `starter`
- **Infrastructure**: `docker`, `kubernetes`, `aws`, `deploy`, `ci`, `cd`, `monitor`

## 📦 Installation Guide

### What Gets Installed

#### Files Created
- `/root/clone_repos/.clone_helper.sh` - Main clone function with tab completion
- `/root/clone_repos/config.json` - GitHub configuration (created on first run)

#### Shell Configuration Modified
- Adds source line to `~/.bashrc` or `~/.zshrc`
- Adds `alias c='clear'` (if not already present)

#### Dependencies Installed
- `git` - For cloning repositories
- `curl` - For GitHub API calls
- `jq` - For better JSON parsing (optional)

### Installation Steps

1. **Make installer executable**:
   ```bash
   chmod +x /root/clone_repos/install_smart_clone.sh
   ```

2. **Run the installer**:
   ```bash
   ./install_smart_clone.sh
   ```

3. **Reload your shell**:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

### First Run Setup
On first use, you'll be prompted to configure:
- **GitHub Username**: Your GitHub username
- **GitHub Token** (optional but recommended): For private repos access
  - Create at: https://github.com/settings/tokens
  - Required scope: `repo` (for private repositories)

### Manual Installation

#### Option 1: One-liner Installation
```bash
curl -s https://raw.githubusercontent.com/kadavilrahul/clone_repos/main/install_smart_clone.sh | bash
```

#### Option 2: Download and Install
```bash
# Download the installer
wget https://raw.githubusercontent.com/kadavilrahul/clone_repos/main/install_smart_clone.sh

# Make it executable
chmod +x install_smart_clone.sh

# Run the installer
./install_smart_clone.sh
```

#### Option 3: Clone the Repository
```bash
# Clone the repository
git clone https://github.com/kadavilrahul/clone_repos.git
cd clone_repos

# Run the installer
chmod +x install_smart_clone.sh
./install_smart_clone.sh
```

## ⚙️ Configuration

### Main Configuration File: `config.json`

```json
{
  "github": {
    "username": "your_github_username",
    "token": "your_personal_access_token"
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
```

### Configuration Options

- **username**: Your GitHub username
- **token**: Personal access token (optional for public repos)
- **default_path**: Default directory for cloning
- **favorites**: List of favorite repositories
- **recent**: Recently accessed repositories
- **filters**: Repository filtering preferences

### GitHub Token Setup

**Option 1: Environment variable (recommended)**
```bash
export GITHUB_TOKEN="your_github_token_here"
```

**Option 2: Edit config.json (not recommended for security)**
```bash
# See config.json for structure
```

### Install Optional Dependencies
```bash
# For enhanced functionality
sudo apt install tree cloc fzf jq

# Or on macOS
brew install tree cloc fzf jq
```

## 🔒 Security

### Important Security Notes

⚠️ **GitHub Token Storage**: The GitHub token is stored in plain text in `config.json`. Consider:

1. **File Permissions**: Ensure config.json has restricted permissions
   ```bash
   chmod 600 /root/clone_repos/config.json
   ```

2. **Environment Variables**: For better security, consider using environment variables:
   ```bash
   export GITHUB_TOKEN="your_token_here"
   ```

3. **Token Scopes**: Use minimal required scopes:
   - `repo` - For private repository access
   - `public_repo` - For public repositories only

### Secure Token Management
```bash
# Method 1: Environment variable
echo 'export GITHUB_TOKEN="your_token"' >> ~/.bashrc
source ~/.bashrc

# Method 2: Secure file
echo "your_token" > ~/.github_token
chmod 600 ~/.github_token
```

### Best Practices

- Regularly rotate your GitHub tokens
- Use tokens with minimal required permissions
- Keep config files in secure locations
- Don't commit tokens to version control
- Never commit GitHub tokens to version control

## 🎯 Use Cases & Examples

### 1. **Project Analysis**
```bash
# Analyze any project directory
./report.sh /path/to/your/project report

# Get quick overview with statistics
./report.sh ~/my-projects/web-app

# Analyzing a Python Project
./report.sh ~/my-python-app report
# Generates comprehensive report with:
# - Project structure
# - Python file statistics
# - Security scan results
# - Function definitions
```

### 2. **Codebase Comparison**
```bash
# Compare multiple projects
./compare.sh
# Enter paths: ./project1, ./project2, ./project3

# Comparing Multiple Codebases
./compare.sh
# Input multiple paths:
# ~/project-v1
# ~/project-v2
# ~/competitor-analysis
# Results saved with file counts and line totals
```

### 3. **Repository Management**
```bash
# Clone and organize repositories
./clone.sh
# Browse, filter, and clone GitHub repositories

# Cloning Repositories by Language
./clone.sh
# Filter by Python repositories
# Select multiple repos for batch cloning
```

### 4. **Code Auditing**
```bash
# Search for security patterns
./report.sh /path/to/project search "API_KEY"

# Extract all functions for review
./report.sh /path/to/project functions
```

### 5. **Smart Clone Examples**
```bash
# Quick repository access
clone project_name

# Find email-related projects
clone email

# Find web development projects
clone html css javascript

# Find automation scripts
clone automation bot script
```

## 🔧 Dependencies

### Required
- `bash` (4.0+)
- `find`, `wc`, `grep` (standard Unix tools)
- `git` (for clone.sh and git statistics)

### Optional (Enhanced Features)
- `tree` - Better project structure visualization
- `cloc` - Detailed code counting
- `jq` - JSON parsing for configuration
- `fzf` - Enhanced interactive selection
- `rg` (ripgrep) - Faster searching

### Installation Commands
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install tree cloc fzf jq

# CentOS/RHEL
sudo yum install tree cloc fzf jq

# macOS
brew install tree cloc fzf jq

# Arch Linux
sudo pacman -S tree cloc fzf jq
```

## 📁 Output Structure

```
clone_repos/
├── reports/                    # Generated by report.sh
│   ├── project_report_*.md    # Project analysis reports
│   ├── cloc_*.txt            # CLOC output files
│   └── functions_*.txt       # Function extraction results
├── codebase_line_counts.txt   # Generated by compare.sh
└── repos/                     # Default clone location
```

## 🔧 Troubleshooting

### Command Not Found
```bash
# Reload your shell configuration
source ~/.bashrc  # or ~/.zshrc

# Or open a new terminal session
```

### GitHub API Issues
```bash
# Check your configuration
cat /root/clone_repos/config.json

# Test API access
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user/repos
```

### Permission Issues
```bash
# Make sure scripts are executable
chmod +x /root/clone_repos/.clone_helper.sh
chmod +x /root/clone_repos/*.sh

# Check shell configuration
grep -n "clone_helper" ~/.bashrc
```

### No Repositories Found
- Verify your GitHub username is correct
- Check if your token has the required permissions
- Ensure you have repositories in your GitHub account
- Try searching with different keywords

## 🚀 Advanced Usage

### Multiple GitHub Accounts
Create account-specific configurations:
```bash
# Create account-specific config
cp /root/clone_repos/config.json /root/clone_repos/config_work.json

# Use with environment variable
GITHUB_CONFIG=/root/clone_repos/config_work.json clone project
```

### Custom Keywords
Edit the completion function in `.clone_helper.sh` to add your own keywords:
```bash
# Find this section and add your keywords
local keywords=(
    "your_custom_keyword" "another_keyword"
    # ... existing keywords
)
```

### Automation Scripts
Use the clone function in scripts:
```bash
#!/bin/bash
source /root/clone_repos/.clone_helper.sh
clone my_project
cd my_project
# Continue with your automation
```

### Recommended Workflow

1. **Daily Usage**:
   ```bash
   clone project_name    # Quick repository access
   bash report.sh        # Regular analysis
   ```

2. **Weekly Reviews**:
   ```bash
   bash compare.sh       # Compare project progress
   # Review security patterns
   # Update documentation
   ```

3. **Monthly Maintenance**:
   ```bash
   # Update GitHub tokens
   # Clean up old clones
   # Review and update keywords
   ```

## 📈 Recommendations & Future Enhancements

### Current Repository Analysis

#### ✅ **report.sh** - Excellent Foundation
- **Strengths**: Well-structured, colorized output, interactive navigation, multiple analysis types
- **Features**: Project analysis, CLOC integration, function extraction, git statistics, security scanning
- **Code Quality**: Good error handling, modular functions, cross-platform compatibility

#### ✅ **compare.sh** - Recently Improved
- **Strengths**: Enhanced error handling, better input validation, informative output
- **Features**: Multi-codebase line counting, file statistics, robust path handling

#### ⚠️ **clone.sh** - Needs Security Review
- **Strengths**: Comprehensive GitHub integration, favorites management, filtering
- **Security Issue**: Contains hardcoded GitHub token in config.json

### Priority Recommendations

#### 🔒 **Security Enhancements**
1. **Environment Variable Support**: Move GitHub token to environment variables
2. **Config Encryption**: Encrypt sensitive configuration data
3. **Permission Hardening**: Implement proper file permissions
4. **Token Rotation**: Automated token refresh mechanisms

#### 🚀 **Feature Additions**
1. **Batch Operations**: Clone multiple repositories at once
2. **Repository Templates**: Quick setup for new projects
3. **Integration Hooks**: Pre/post clone scripts
4. **Workspace Management**: Organize repositories by projects
5. **Web Dashboard**: Browser-based interface for repository management
6. **API Integration**: Support for GitLab, Bitbucket, and other platforms

#### 📊 **Analysis Improvements**
1. **Dependency Analysis**: Scan for outdated dependencies
2. **Code Quality Metrics**: Integration with linting tools
3. **Performance Profiling**: Identify performance bottlenecks
4. **Documentation Generation**: Auto-generate project documentation
5. **Vulnerability Scanning**: Integration with security scanning tools
6. **License Compliance**: Track and report on license usage

#### 🔧 **Usability Enhancements**
1. **GUI Interface**: Web-based dashboard for repository management
2. **Search Improvements**: Better fuzzy matching algorithms
3. **History Tracking**: Track clone and analysis history
4. **Export Options**: Multiple output formats for reports
5. **Plugin System**: Extensible architecture for custom tools
6. **Configuration Wizard**: Guided setup for new users

### Recommended Implementation Phases

#### **Phase 1: Security & Stability**
- Implement environment variable support
- Add configuration encryption
- Enhance error handling
- Add comprehensive logging

#### **Phase 2: Feature Enhancement**
- Add batch operations
- Implement workspace management
- Create web dashboard
- Add plugin system

#### **Phase 3: Advanced Analytics**
- Integrate dependency scanning
- Add performance profiling
- Implement vulnerability detection
- Create advanced reporting

## 🤝 Contributing

### Development Guidelines
- Follow existing code style
- Add error handling for new features
- Update documentation
- Test on multiple platforms when possible

### Contributing Process
1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 File Structure

```
/root/clone_repos/
├── .clone_helper.sh          # Main clone function
├── config.json               # GitHub configuration
├── install_smart_clone.sh    # Installation script
├── clone.sh                  # Alternative clone script
├── compare.sh                # Repository comparison
├── report.sh                 # Analysis and reporting
├── test_installation.sh      # Installation testing
├── sample_config.json        # Configuration template
├── README.md                 # This comprehensive guide
└── README_original_backup.md # Backup of original README
```

## 📝 License

This toolkit is provided as-is for personal and professional use.

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify GitHub token permissions
3. Ensure all dependencies are installed
4. Check shell configuration files
5. Review the logs for error messages

---

**Happy Coding!** 🚀

This comprehensive toolkit provides everything you need for efficient repository management, analysis, and intelligent cloning with advanced features and security considerations.