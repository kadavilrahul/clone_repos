#!/bin/bash

# -----------------------------------
# ✅ STEP 1: Install Required Tools
# -----------------------------------
echo "🔧 Checking and installing required tools..."

install_if_missing() {
  if ! command -v "$1" &>/dev/null; then
    echo "Installing $1..."
    sudo apt update && sudo apt install -y "$1"
  fi
}

install_if_missing git
install_if_missing bash
install_if_missing fzf

# -----------------------------------
# 📦 STEP 2: GitHub Repo List
# -----------------------------------
declare -A REPO_LIST=(
  ["agent-with-user-interface"]="https://github.com/kadavilrahul/agent-with-user-interface.git"
  ["browser-use-chrome-extension-testing"]="https://github.com/kadavilrahul/browser-use-chrome-extension-testing.git"
  ["browser-use-shell"]="https://github.com/kadavilrahul/browser-use-shell.git"
  ["browser-use-web-terminal-ui"]="https://github.com/kadavilrahul/browser-use-web-terminal-ui.git"
  ["chrome_remote_desktop_and_xrdp"]="https://github.com/kadavilrahul/chrome_remote_desktop_and_xrdp.git"
  ["coding_task_manager"]="https://github.com/kadavilrahul/coding_task_manager.git"
  ["ebay_scraper"]="https://github.com/kadavilrahul/ebay_scraper.git"
  ["ecommerce_chatbot"]="https://github.com/kadavilrahul/ecommerce_chatbot.git"
  ["email_automation_private"]="https://github.com/kadavilrahul/email_automation_private.git"
  ["excel-csv-deduplicator"]="https://github.com/kadavilrahul/excel-csv-deduplicator.git"
  ["file-versioning-inotify"]="https://github.com/kadavilrahul/file-versioning-inotify.git"
  ["generate_html_from_csv"]="https://github.com/kadavilrahul/generate_html_from_csv.git"
  ["generate_ssh_keys"]="https://github.com/kadavilrahul/generate_ssh_keys.git"
  ["install_wordpress_on_lamp"]="https://github.com/kadavilrahul/install_wordpress_on_lamp.git"
  ["installation_methods"]="https://github.com/kadavilrahul/installation_methods.git"
  ["long_term_testing_projects"]="https://github.com/kadavilrahul/long_term_testing_projects.git"
  ["modfications_scripts_private"]="https://github.com/kadavilrahul/modfications_scripts_private.git"
  ["old_scripts"]="https://github.com/kadavilrahul/old_scripts.git"
  ["reddit-bot"]="https://github.com/kadavilrahul/reddit-bot.git"
  ["setup_email_system"]="https://github.com/kadavilrahul/setup_email_system.git"
  ["test"]="https://github.com/kadavilrahul/test.git"
  ["useful_commands"]="https://github.com/kadavilrahul/useful_commands.git"
  ["woocommerce_import_data"]="https://github.com/kadavilrahul/woocommerce_import_data.git"
  ["woocommerce_searchbar_plugin"]="https://github.com/kadavilrahul/woocommerce_searchbar_plugin.git"
)

REPO_NAMES=("${!REPO_LIST[@]}")
IFS=$'\n' REPO_NAMES_SORTED=($(sort <<<"${REPO_NAMES[*]}"))
unset IFS

echo ""
echo "📚 Available Repositories:"
for i in "${!REPO_NAMES_SORTED[@]}"; do
  printf "%2d) %s\n" $((i + 1)) "${REPO_NAMES_SORTED[$i]}"
done

# -----------------------------------
# 🔢 STEP 3: Select Repository
# -----------------------------------
# 'select' is a built-in Bash construct, no installation needed.
echo ""
echo "Choose a repository to clone:"
select selected_repo in "${REPO_NAMES_SORTED[@]}"; do
  if [ -z "$selected_repo" ]; then
    echo "❌ Invalid selection. Exiting."
    exit 1
  fi

  repo_url="${REPO_LIST[$selected_repo]}"

  # -----------------------------------
  # 📁 STEP 4: Clone Repo
  # -----------------------------------
  # Clones the repository into the 'repos' directory
  mkdir -p repos
  cd repos || exit

  if [ -d "$selected_repo" ]; then
    echo "⚠️ Directory '$selected_repo' already exists. Skipping clone."
  else
    echo "🔄 Cloning $selected_repo..."
    git clone "$repo_url"
  fi

  cd "$selected_repo" || { echo "❌ Failed to cd into $selected_repo"; exit 1; }

  # -----------------------------------
  # ✅ STEP 5: Execute setup.sh and run.sh
  # -----------------------------------
  [ -f "setup.sh" ] && has_setup=true || has_setup=false
  [ -f "run.sh" ] && has_run=true || has_run=false

  echo ""
  echo "🔍 Script availability:"
  $has_setup && echo "✅ setup.sh found" || echo "❌ setup.sh missing"
  $has_run && echo "✅ run.sh found" || echo "❌ run.sh missing"

  if $has_setup; then
    read -p "➡️ Do you want to run setup.sh? (y/n): " run_setup
    [[ "$run_setup" == "y" ]] && chmod +x setup.sh && ./setup.sh
  fi

  if $has_run; then
    read -p "▶️ Do you want to run run.sh? (y/n): " run_run
    [[ "$run_run" == "y" ]] && chmod +x run.sh && ./run.sh
  fi
  break
done
