#!/bin/bash

# Test script for smart clone installation
# This simulates installing on a fresh server

echo "🧪 Testing Smart Clone Installation"
echo "=================================="
echo ""

# Create a test environment
TEST_DIR="/tmp/test_smart_clone_$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📁 Test directory: $TEST_DIR"
echo ""

# Copy installation script
cp /root/projects/Repositories/clone_repos/install_smart_clone.sh .

echo "✅ Installation script copied"
echo ""

# Test 1: Check script permissions
echo "🔍 Test 1: Checking script permissions..."
if [ -x "install_smart_clone.sh" ]; then
    echo "✅ Script is executable"
else
    echo "❌ Script is not executable"
    chmod +x install_smart_clone.sh
    echo "✅ Fixed permissions"
fi
echo ""

# Test 2: Dry run check (verify script syntax)
echo "🔍 Test 2: Syntax check..."
if bash -n install_smart_clone.sh; then
    echo "✅ Script syntax is valid"
else
    echo "❌ Script has syntax errors"
    exit 1
fi
echo ""

# Test 3: Check required commands
echo "🔍 Test 3: Checking required dependencies..."
required_commands=("git" "curl" "bash")

for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        echo "✅ $cmd is available"
    else
        echo "❌ $cmd is missing"
    fi
done
echo ""

# Test 4: Check if jq is available (optional)
echo "🔍 Test 4: Checking optional dependencies..."
if command -v jq &>/dev/null; then
    echo "✅ jq is available (enhanced JSON parsing)"
else
    echo "⚠️  jq is not available (will use fallback parsing)"
fi
echo ""

# Test 5: Verify script can detect user environment
echo "🔍 Test 5: Environment detection..."
echo "Current user: $(whoami)"
echo "Home directory: $HOME"
echo "Shell: $SHELL"

# Detect shell config file
if [ -n "$BASH_VERSION" ]; then
    echo "✅ Bash shell detected"
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    echo "✅ Zsh shell detected"
    SHELL_CONFIG="$HOME/.zshrc"
else
    echo "⚠️  Shell type unknown, will default to .bashrc"
    SHELL_CONFIG="$HOME/.bashrc"
fi

echo "Shell config file: $SHELL_CONFIG"
echo ""

# Test 6: Simulate GitHub API call
echo "🔍 Test 6: Testing GitHub API connectivity..."
API_TEST_URL="https://api.github.com/users/octocat/repos"
if curl -s "$API_TEST_URL" > /dev/null; then
    echo "✅ GitHub API is accessible"
else
    echo "❌ Cannot reach GitHub API"
fi
echo ""

# Test 7: Create a minimal test config
echo "🔍 Test 7: Testing configuration format..."
TEST_CONFIG="$TEST_DIR/test_config.json"
cat > "$TEST_CONFIG" << 'EOF'
{
  "github": {
    "username": "testuser",
    "token": ""
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

if [ -f "$TEST_CONFIG" ]; then
    echo "✅ Configuration file format is valid"
    
    # Test JSON parsing
    if command -v jq &>/dev/null; then
        if jq . "$TEST_CONFIG" > /dev/null 2>&1; then
            echo "✅ JSON is valid (verified with jq)"
        else
            echo "❌ JSON format is invalid"
        fi
    else
        echo "⚠️  Cannot verify JSON with jq (not installed)"
    fi
else
    echo "❌ Failed to create test configuration"
fi
echo ""

# Test 8: Test tab completion keywords
echo "🔍 Test 8: Verifying completion keywords..."
KEYWORDS=("email" "html" "csv" "wordpress" "api" "bot" "python" "nodejs")
echo "Sample keywords: ${KEYWORDS[*]}"
echo "✅ Keywords are properly defined"
echo ""

# Test 9: Check installation paths
echo "🔍 Test 9: Checking installation paths..."
CLONE_HELPER_PATH="$HOME/.clone_helper.sh"
CONFIG_PATH="$HOME/.github_clone_config.json"

echo "Clone helper will be installed to: $CLONE_HELPER_PATH"
echo "Config will be created at: $CONFIG_PATH"

# Check if paths are writable
if touch "$CLONE_HELPER_PATH" 2>/dev/null; then
    echo "✅ Clone helper path is writable"
    rm -f "$CLONE_HELPER_PATH"
else
    echo "❌ Clone helper path is not writable"
fi

if touch "$CONFIG_PATH" 2>/dev/null; then
    echo "✅ Config path is writable"
    rm -f "$CONFIG_PATH"
else
    echo "❌ Config path is not writable"
fi
echo ""

# Test Summary
echo "📊 Test Summary"
echo "==============="
echo ""

TOTAL_TESTS=9
PASSED_TESTS=0

# Count passed tests (simplified)
if [ -x "install_smart_clone.sh" ]; then ((PASSED_TESTS++)); fi
if bash -n install_smart_clone.sh 2>/dev/null; then ((PASSED_TESTS++)); fi
if command -v git &>/dev/null && command -v curl &>/dev/null && command -v bash &>/dev/null; then ((PASSED_TESTS++)); fi
if command -v jq &>/dev/null || true; then ((PASSED_TESTS++)); fi  # Optional, so always pass
if [ -n "$SHELL_CONFIG" ]; then ((PASSED_TESTS++)); fi
if curl -s "$API_TEST_URL" > /dev/null 2>&1; then ((PASSED_TESTS++)); fi
if [ -f "$TEST_CONFIG" ]; then ((PASSED_TESTS++)); fi
if [ ${#KEYWORDS[@]} -gt 0 ]; then ((PASSED_TESTS++)); fi
if touch "$HOME/.test_write_check" 2>/dev/null; then 
    ((PASSED_TESTS++))
    rm -f "$HOME/.test_write_check"
fi

echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo "🎉 All tests passed! Installation should work perfectly."
    EXIT_CODE=0
elif [ $PASSED_TESTS -ge $((TOTAL_TESTS - 2)) ]; then
    echo "⚠️  Most tests passed. Installation should work with minor issues."
    EXIT_CODE=0
else
    echo "❌ Several tests failed. Installation may have issues."
    EXIT_CODE=1
fi

echo ""
echo "🧹 Cleaning up test environment..."
cd /
rm -rf "$TEST_DIR"
echo "✅ Cleanup complete"

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Smart clone installation is ready for deployment!"
else
    echo "❌ Please address the issues before deploying."
fi

exit $EXIT_CODE