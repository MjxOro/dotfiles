#!/usr/bin/env bash

# Bash version check
if [[ "${BASH_VERSION}" < "4.0" ]]; then
  echo "Error: Bash 4.0+ required. Current: ${BASH_VERSION}"
  exit 1
fi

# Enable debug mode if VERBOSE=1
if [[ "${VERBOSE:-0}" == "1" ]]; then
  echo -e "\033[0;36mDEBUG: install.sh script interpreter has started.\033[0m"
fi

# --- Robust SCRIPT_DIR Initialization ---
set +e
SCRIPT_DIR_RAW="${BASH_SOURCE[0]}"
if [[ -z "$SCRIPT_DIR_RAW" ]]; then
  echo -e "\033[0;31mFATAL ERROR: BASH_SOURCE[0] is empty. Cannot determine script directory.\033[0m" >&2
  exit 1
fi
SCRIPT_DIR_TEMP="$(cd "$(dirname "$SCRIPT_DIR_RAW")" >/dev/null 2>&1 && pwd)"
SCRIPT_DIR_EXIT_CODE=$?
set -e # Enable errexit now
if [ $SCRIPT_DIR_EXIT_CODE -ne 0 ] || [ -z "$SCRIPT_DIR_TEMP" ] || [ ! -d "$SCRIPT_DIR_TEMP" ]; then
  echo -e "\033[0;31mFATAL ERROR: Failed to determine script directory.\033[0m" >&2
  exit 1
fi
SCRIPT_DIR="$SCRIPT_DIR_TEMP"
if [[ "${VERBOSE:-0}" == "1" ]]; then
  echo -e "\033[0;36mDEBUG: Script directory determined as: $SCRIPT_DIR\033[0m"
fi
# --- End of SCRIPT_DIR Initialization ---

# ANSI color codes
BOLD='\033[1m'
UNDERLINE='\033[4m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Function to print section header
print_header() {
  echo
  print_message "$PURPLE" "========== $1 =========="
  echo
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to display help message
show_help() {
  echo -e "${BOLD}Dotfiles Installation Script${NC}"
  echo
  echo "Usage: ./install.sh [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help           Show this help message"
  echo "  -d, --dotfiles-dir   Specify dotfiles directory (default: script location)"
  echo "  -l, --link-only      Only link dotfiles, don't install dependencies"
  echo "  -u, --unlink         Unlink dotfiles for specified packages (or all)"
  echo "  -y, --yes            Assume yes for all prompts (use with caution)"
  echo "  -i, --interactive    Force interactive mode for prompts (default if TTY)"
  echo "  -q, --quiet          Minimize output"
  echo "  -p, --packages       Comma-separated list of packages to link/unlink (default: all)"
  echo "                       (e.g., nvim,tmux,zsh)"
  echo
  echo "Environment Variables:"
  echo "  VERBOSE=1            Enable verbose debug output"
  echo
  echo "Example:"
  echo "  ./install.sh -d ~/my-dotfiles -p nvim,zsh"
  echo "  ./install.sh -u       # Unlink all managed dotfiles"
  echo "  VERBOSE=1 ./install.sh # Run with debug output"
}

# Parse arguments
DOTFILES_DIR="$SCRIPT_DIR" 
UNLINK=false
ASSUME_YES=false
INTERACTIVE=false
QUIET=false
PACKAGES_TO_PROCESS="" 
LINK_ONLY=false

if [ -t 0 ] && [ -t 1 ]; then INTERACTIVE=true; fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -h | --help) show_help; exit 0 ;;
  -d | --dotfiles-dir) DOTFILES_DIR="$2"; shift; shift ;;
  -l | --link-only) LINK_ONLY=true; shift ;;
  -u | --unlink) UNLINK=true; shift ;;
  -y | --yes) ASSUME_YES=true; INTERACTIVE=false; shift ;;
  -i | --interactive) INTERACTIVE=true; ASSUME_YES=false; shift ;;
  -q | --quiet) QUIET=true; INTERACTIVE=false; shift ;;
  -p | --packages) PACKAGES_TO_PROCESS="$2"; shift; shift ;; 
  *) print_message "$RED" "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

if [ -d "$DOTFILES_DIR" ]; then DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"; else
  print_message "$RED" "Error: Dotfiles directory not found at '$DOTFILES_DIR'"
  exit 1
fi
LINK_SRC_BASE_DIR="$DOTFILES_DIR" # Source for packages is the DOTFILES_DIR itself
if [ ! -d "$LINK_SRC_BASE_DIR" ]; then
  print_message "$RED" "Error: Source base directory for packages not found at: $LINK_SRC_BASE_DIR"
  exit 1
fi

get_available_packages() {
  # Exclude .git and other common VCS/temporary files/dirs from being listed as packages
  find "$LINK_SRC_BASE_DIR" -mindepth 1 -maxdepth 1 \
    -not -path "$LINK_SRC_BASE_DIR/.git*" \
    -not -name ".DS_Store" \
    -not -name "README.md" \
    -not -name "AGENTS.md" \
    -not -name "install.sh" \
    -not -name "*.itermcolors" \
    -exec basename {} \; | sort
}

ask_yes_no() {
  local prompt_msg="$1" ans_default="${2:-y}" prompt_ind
  if [ "$ASSUME_YES" = true ]; then return 0; fi
  if [ "$INTERACTIVE" = false ]; then if [ "$ans_default" = "y" ]; then return 0; else return 1; fi; fi
  if [ "$ans_default" = "y" ]; then prompt_ind="[Y/n]"; else prompt_ind="[y/N]"; fi
  while true; do
    read -r -p "$(echo -e "${YELLOW}${prompt_msg} ${prompt_ind} ${NC}")" yn_ans
    yn_ans=$(echo "$yn_ans" | tr '[:upper:]' '[:lower:]')
    case $yn_ans in
    y | yes) return 0 ;; n | no) return 1 ;;
    "") if [ "$ans_default" = "y" ]; then return 0; else return 1; fi ;;
    *) print_message "$RED" "Please answer 'yes' or 'no'." ;;
    esac
  done
}

process_single_item() {
  local action="$1"
  local source_path="$2"
  local target_path="$3"
  local display_name="$4"
  local main_backup_dir="$5"

  echo -e "${PURPLE}  DEBUG: process_single_item: action='$action', source='$source_path', target='$target_path', name='$display_name'${NC}"

  if [ "$action" = "link" ]; then
    if [ ! -e "$source_path" ]; then
        print_message "$RED" "  ERROR: Source path '$source_path' for '$display_name' does not exist. Skipping."
        return 1
    fi
    local target_parent_dir; target_parent_dir=$(dirname "$target_path")
    if [ ! -d "$target_parent_dir" ]; then
      if [ "$QUIET" = false ]; then print_message "$BLUE" "  Creating parent directory '$target_parent_dir' for '$display_name'"; fi
      if ! mkdir -p "$target_parent_dir"; then
        print_message "$RED" "  ERROR: Failed to create parent directory '$target_parent_dir' for '$display_name'."; return 1
      fi
    fi

    if [ -L "$target_path" ]; then
      local current_link_target; current_link_target=$(readlink -f "$target_path" 2>/dev/null || true)
      local expected_link_target; expected_link_target=$(readlink -f "$source_path" 2>/dev/null || true)
      echo -e "${PURPLE}    DEBUG: Target '$target_path' is a symlink. Current: '$current_link_target', Expected: '$expected_link_target'${NC}"
      if [[ "$current_link_target" == "$expected_link_target" ]]; then
        if [ "$QUIET" = false ]; then print_message "$GREEN" "  Symlink '$target_path' for '$display_name' already correct."; fi
        return 0 
      else
        if ask_yes_no "  Target '$target_path' for '$display_name' is a symlink pointing to '$current_link_target'. Replace it?" "y"; then
          if [ "$QUIET" = false ]; then print_message "$BLUE" "    Removing existing symlink '$target_path'"; fi
          if ! rm "$target_path"; then
             print_message "$RED" "    ERROR: Failed to remove existing symlink '$target_path'."; return 1
          fi
        else
          if [ "$QUIET" = false ]; then print_message "$YELLOW" "    Skipping replacement of symlink '$target_path'."; fi
          return 1 
        fi
      fi
    elif [ -e "$target_path" ]; then
      local conflict_desc="item"; if [ -d "$target_path" ]; then conflict_desc="directory"; elif [ -f "$target_path" ]; then conflict_desc="file"; fi
      echo -e "${PURPLE}    DEBUG: Target '$target_path' exists and is a $conflict_desc.${NC}"
      if ask_yes_no "  Target '$target_path' for '$display_name' ($conflict_desc) exists. Backup & remove it?" "y"; then
        backup_made_globally=true 
        local item_backup_path="$main_backup_dir/$display_name" 
        if [ "$QUIET" = false ]; then print_message "$BLUE" "    Backing up '$target_path' to '$item_backup_path'"; fi
        mkdir -p "$(dirname "$item_backup_path")"
        if cp -aL "$target_path" "$item_backup_path"; then
          if [ "$QUIET" = false ]; then print_message "$GRAY" "      Backed up."; fi
          if [ "$QUIET" = false ]; then print_message "$BLUE" "    Removing '$target_path'"; fi
          if ! rm -rf "$target_path"; then
            print_message "$RED" "    ERROR: Failed to remove '$target_path'."; return 1
          fi
        else
          print_message "$RED" "    ERROR: Failed to backup '$target_path'."; return 1
        fi
      else
        if [ "$QUIET" = false ]; then print_message "$YELLOW" "    Skipping removal of '$target_path'."; fi
        return 1 
      fi
    fi
    if [ "$QUIET" = false ]; then echo -n -e "${CYAN}  Linking '$source_path' to '$target_path'... ${NC}"; fi
    if ln -sfn "$source_path" "$target_path"; then
      if [ "$QUIET" = false ]; then echo -e "${GREEN}✓ Linked${NC}"; fi
      return 0
    else
      if [ "$QUIET" = false ]; then echo -e "${RED}✗ Link Failed${NC}"; fi
      print_message "$RED" "  ERROR: Failed to link '$display_name'."
      return 1
    fi

  elif [ "$action" = "unlink" ]; then
    if [ ! -L "$target_path" ]; then
      if [ -e "$target_path" ] && [ "$QUIET" = false ]; then
        print_message "$YELLOW" "  Skipping '$target_path' for '$display_name': Not a symlink."
      elif [ "$QUIET" = false ] && [ ! -e "$target_path" ]; then
         echo -e "${PURPLE}    DEBUG: Target '$target_path' for unlink does not exist.${NC}"
      fi
      return 0 
    fi

    local current_link_target; current_link_target=$(readlink -f "$target_path" 2>/dev/null || true)
    local expected_link_target; expected_link_target=$(readlink -f "$source_path" 2>/dev/null || true)
    echo -e "${PURPLE}    DEBUG: Target '$target_path' is a symlink. Current: '$current_link_target', Expected: '$expected_link_target'${NC}"

    if [[ "$current_link_target" == "$expected_link_target" ]]; then
      if [ "$QUIET" = false ]; then echo -n -e "${CYAN}  Unlinking '$target_path' for '$display_name'... ${NC}"; fi
      if rm "$target_path"; then
        if [ "$QUIET" = false ]; then echo -e "${GREEN}✓ Unlinked${NC}"; fi
        return 0
      else
        if [ "$QUIET" = false ]; then echo -e "${RED}✗ Failed to remove${NC}"; fi
        print_message "$RED" "  ERROR: Failed to remove symlink '$target_path'."
        return 1
      fi
    else
      if [ "$QUIET" = false ]; then
        print_message "$YELLOW" "  Skipping '$target_path' for '$display_name': Symlink points to '$current_link_target', not expected '$expected_link_target'."
      fi
      return 0 
    fi
  else
    print_message "$RED" "Unknown action '$action' in process_single_item."
    return 1
  fi
}

manage_dotfiles() {
  local action="$1" 
  local header_msg=""
  if [ "$action" = "link" ]; then header_msg="Linking Dotfiles (Manual Symlinks)"; else header_msg="Unlinking Dotfiles (Manual Symlinks)"; fi
  print_header "$header_msg"

  # Enable more verbose debugging
  set -E  # Inherit error trap
  trap 'echo -e "\033[0;31mERROR: Command failed at line $LINENO: $BASH_COMMAND\033[0m"' ERR

  local packages_to_act_on_arr=()
  if [ -n "$PACKAGES_TO_PROCESS" ]; then 
    IFS=',' read -ra packages_to_act_on_arr <<<"$PACKAGES_TO_PROCESS"
  else
    mapfile -t packages_to_act_on_arr < <(get_available_packages) 
  fi

  if [ ${#packages_to_act_on_arr[@]} -eq 0 ]; then
    print_message "$YELLOW" "No packages specified or found to $action."
    return 0
  fi

  if [ "$QUIET" = false ]; then print_message "$BLUE" "Packages to $action: ${packages_to_act_on_arr[*]}"; fi
  local overall_succ_cnt=0 overall_fail_cnt=0 overall_fail_list=()
  local ts; ts=$(date +%Y%m%d_%H%M%S) 
  local main_backup_dir="$HOME/.dotfiles_backup/$ts"
  backup_made_globally=false 

  echo -e "${PURPLE}DEBUG: Starting package processing loop with ${#packages_to_act_on_arr[@]} packages${NC}"
  
  for package_name in "${packages_to_act_on_arr[@]}"; do
    echo -e "${PURPLE}DEBUG: Starting to process package '$package_name'${NC}"
    local package_source_dir="$LINK_SRC_BASE_DIR/$package_name"
    if [ ! -d "$package_source_dir" ]; then
      print_message "$YELLOW" "Package source directory '$package_source_dir' not found. Skipping '$package_name'."
      ((overall_fail_cnt++)); overall_fail_list+=("$package_name (src dir missing)")
      continue
    fi
    if [ "$QUIET" = false ]; then print_message "$CYAN" "Processing package '$package_name':"; fi
    echo -e "${PURPLE}DEBUG: Processing package '$package_name' from '$package_source_dir'${NC}"


    local items_processed_in_package=0
    local items_succeeded_in_package=0
    local items_failed_in_package=0

    # Rule 1: Top-level non-dot-prefixed directories (like nvim, starship) link to ~/.config/
    if [[ "$package_name" != .* ]]; then # e.g. "nvim", "starship"
      echo -e "${PURPLE}  DEBUG: Applying Rule 1 for '$package_name'${NC}"
      items_processed_in_package=$((items_processed_in_package + 1))
      if process_single_item "$action" "$package_source_dir" "$HOME/.config/$package_name" "$package_name" "$main_backup_dir"; then
        items_succeeded_in_package=$((items_succeeded_in_package + 1))
      else
        items_failed_in_package=$((items_failed_in_package + 1))
      fi

      # Special handling for ghostty on macOS - link config file directly
      if [[ "$package_name" == "ghostty" && "$(uname -s)" == "Darwin" ]]; then
        local ghostty_config_source="$package_source_dir/config"
        local ghostty_config_target="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
        if [ -f "$ghostty_config_source" ]; then
          items_processed_in_package=$((items_processed_in_package + 1))
          echo -e "${PURPLE}  DEBUG: Applying Ghostty macOS-specific config linking${NC}"
          if process_single_item "$action" "$ghostty_config_source" "$ghostty_config_target" "ghostty/macOS-config" "$main_backup_dir"; then
            items_succeeded_in_package=$((items_succeeded_in_package + 1))
          else
            items_failed_in_package=$((items_failed_in_package + 1))
          fi
        fi
      fi
    fi

    # Rule 2: For specific packages, look *inside* them for specific dotfiles to link to home
    echo -e "${PURPLE}  DEBUG: Applying Rule 2 for '$package_name'${NC}"
    local found_items_in_package=()
    
    # Use a safer approach to find dot files
    echo -e "${PURPLE}  DEBUG: Searching for dot items in '$package_source_dir'${NC}"
    while IFS= read -r -d '' item; do
        local item_basename=$(basename "$item")
        echo -e "${PURPLE}    DEBUG: Found item: $item_basename${NC}"
        
        # Only link specific dotfiles (.zshrc, .tmux, .tmux.conf, .claude) to home directory
        if [[ "$item_basename" == ".zshrc" || "$item_basename" == ".tmux" || "$item_basename" == ".tmux.conf" || "$item_basename" == ".claude" ]]; then
          found_items_in_package+=("$item")
          echo -e "${PURPLE}    DEBUG: Added to processing list: $item${NC}"
        else
          echo -e "${PURPLE}    DEBUG: Skipping item (not in allowed home dotfiles): $item_basename${NC}"
        fi
    done < <(find "$package_source_dir" -mindepth 1 -maxdepth 1 -name ".*" -print0 2>/dev/null || echo -e "${RED}Find command failed!${NC}")

    echo -e "${PURPLE}  DEBUG: Found ${#found_items_in_package[@]} dot-items in '$package_name'${NC}"
    
    if [ ${#found_items_in_package[@]} -gt 0 ]; then
      echo -e "${PURPLE}    DEBUG: Found dot-items in '$package_name': ${found_items_in_package[*]}${NC}"
      for source_item_abs_path in "${found_items_in_package[@]}"; do
        local item_basename; item_basename=$(basename "$source_item_abs_path")
        echo -e "${PURPLE}      DEBUG: Processing inner item '$item_basename' from '$package_name'${NC}"
        items_processed_in_package=$((items_processed_in_package + 1))
        if process_single_item "$action" "$source_item_abs_path" "$HOME/$item_basename" "$item_basename" "$main_backup_dir"; then
          items_succeeded_in_package=$((items_succeeded_in_package + 1))
        else
          items_failed_in_package=$((items_failed_in_package + 1))
        fi
      done
    fi
    
    if [ "$QUIET" = false ] && [ $items_processed_in_package -gt 0 ]; then
      if [ $items_failed_in_package -eq 0 ]; then
        print_message "$GREEN" "  Package '$package_name' processed successfully ($items_succeeded_in_package item(s))."
      else
        print_message "$YELLOW" "  Package '$package_name': $items_succeeded_in_package/$items_processed_in_package item(s) succeeded."
      fi
    fi

    if [ $items_processed_in_package -gt 0 ]; then # Only count package if items were attempted
        if [ $items_failed_in_package -eq 0 ]; then
            overall_succ_cnt=$((overall_succ_cnt + 1))
        else
            overall_fail_cnt=$((overall_fail_cnt + 1))
            overall_fail_list+=("$package_name (partial/full failure)")
        fi
    fi
    
    echo -e "${PURPLE}DEBUG: Completed processing package '$package_name'${NC}"
  done 
  
  # Disable the error trap
  trap - ERR
  set +E

  echo; print_message "$BLUE" "$action Summary"
  print_message "$GREEN" "Packages fully successful: $overall_succ_cnt" # Changed wording
  if [ $overall_fail_cnt -gt 0 ]; then
    print_message "$RED" "Packages with failures or not processed as expected: $overall_fail_cnt (${overall_fail_list[*]}). Check output."
  fi
  if [ "$action" = "link" ] && [ "$backup_made_globally" = true ]; then
    if [ -d "$main_backup_dir" ] && [ "$(ls -A "$main_backup_dir")" ]; then
      echo; print_message "$BLUE" "Backups created in $main_backup_dir"
    fi
  fi
  
  if [ $overall_fail_cnt -eq 0 ]; then
    # Success if no failures, even if succ_cnt is 0 (e.g. unlinking already unlinked items)
    print_message "$GREEN" "✨ All specified packages processed successfully for $action!"
    return 0
  else
    print_message "$RED" "⚠️ Some packages had issues during $action. Review logs."
    return 1
  fi
}


# --- Helper Install Functions & OS Specific Dependencies ---
# (Omitted for brevity - assume they are the same as your last full script)
_install_starship_via_curl_script() { 
  if command_exists starship; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Starship is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Starship (prompt) via official script?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for Starship script. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing Starship (curl ... | sh)... ${NC}"
    local s_out s_ec
    if [ "$QUIET" = true ]; then
      s_out=$(curl -fsSL https://starship.rs/install.sh | sh -s -- -y 2>&1); s_ec=$?
    else
      echo
      curl -fsSL https://starship.rs/install.sh | sh -s -- -y; s_ec=$?
    fi
    if [ $s_ec -eq 0 ] && command_exists starship; then echo -e "${GREEN}✓${NC}"; else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Starship script install failed (code: $s_ec)."
      if [ -n "$s_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $s_out"; fi
    fi
  else print_message "$YELLOW" "  Starship script installation skipped."; fi
}
_install_ohmyzsh_script() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Oh My Zsh is already installed."; fi
    return 0
  fi
  if ! command_exists zsh || ! command_exists git || ! command_exists curl; then
    print_message "$YELLOW" "  Zsh, Git, & Curl are required for Oh My Zsh. Install them first."
    return 1
  fi
  if ask_yes_no "  Install Oh My Zsh?" "y"; then
    local omz_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    echo -n -e "${CYAN}    Installing Oh My Zsh (curl ... | sh)... ${NC}"
    local omz_out omz_ec
    if [ "$QUIET" = true ]; then
      omz_out=$(CHSH=no RUNZSH=no curl -fsSL "$omz_url" | sh -s -- --unattended 2>&1); omz_ec=$?
    else
      echo
      CHSH=no RUNZSH=no curl -fsSL "$omz_url" | sh -s -- --unattended; omz_ec=$?
    fi
    if [ -d "$HOME/.oh-my-zsh" ]; then
      echo -e "${GREEN}✓${NC}"
      print_message "$GREEN" "    Oh My Zsh installed."
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Oh My Zsh install failed (dir not found)."
      if [ -n "$omz_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $omz_out"; fi
    fi
  else print_message "$YELLOW" "  Oh My Zsh installation skipped."; fi
}

_set_zsh_default_shell() {
  if ! command_exists zsh; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Zsh not installed, skipping shell change."; fi
    return 0
  fi
  local current_shell; current_shell=$(basename "$SHELL")
  if [ "$current_shell" = "zsh" ]; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Zsh is already the default shell."; fi
    return 0
  fi
  if ask_yes_no "  Set Zsh as default shell? (requires password)" "y"; then
    local zsh_path; zsh_path=$(which zsh)
    echo -n -e "${CYAN}    Changing default shell to Zsh... ${NC}"
    if chsh -s "$zsh_path"; then
      echo -e "${GREEN}✓${NC}"
      print_message "$GREEN" "    Default shell changed to Zsh. Restart terminal to apply."
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    Failed to change shell. Try manually: chsh -s $zsh_path"
    fi
  else print_message "$YELLOW" "  Shell change skipped."; fi
}

_install_bun_script() {
  if command_exists bun; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Bun is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Bun (JavaScript runtime)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for Bun installation. Please install curl."; return 1; fi
    if [[ "$(uname -s)" == "Linux" ]] && ! command_exists unzip; then
      print_message "$RED" "    unzip is required for Bun installation on Linux. Please install unzip first."
      return 1
    fi
    echo -n -e "${CYAN}    Installing Bun (curl ... | bash)... ${NC}"
    local bun_out bun_ec
    if [ "$QUIET" = true ]; then
      bun_out=$(curl -fsSL https://bun.sh/install 2>/dev/null | bash 2>&1); bun_ec=$?
    else
      echo
      curl -fsSL https://bun.sh/install | bash; bun_ec=$?
    fi
    if [ -f "$HOME/.bun/bin/bun" ]; then
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
    fi
    if [ $bun_ec -eq 0 ] && (command_exists bun || [ -f "$HOME/.bun/bin/bun" ]); then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Bun installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Bun installation failed (code: $bun_ec)."
      if [ -n "$bun_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $bun_out"; fi
    fi
  else print_message "$YELLOW" "  Bun installation skipped."; fi
}

_install_opencode_script() {
  if command_exists opencode && opencode --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  OpenCode is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install OpenCode (AI coding assistant)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for OpenCode installation. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing OpenCode (curl ... | bash)... ${NC}"
    local opencode_out opencode_ec
    if [ "$QUIET" = true ]; then
      opencode_out=$(curl -fsSL https://opencode.ai/install 2>/dev/null | bash 2>&1); opencode_ec=$?
    else
      echo
      curl -fsSL https://opencode.ai/install | bash; opencode_ec=$?
    fi
    if [ $opencode_ec -eq 0 ] && command_exists opencode && opencode --version >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    OpenCode installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    OpenCode installation failed (code: $opencode_ec)."
      if [ -n "$opencode_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $opencode_out"; fi
    fi
  else print_message "$YELLOW" "  OpenCode installation skipped."; fi
}

_install_claude_code_script() {
  if command_exists claude && claude --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Claude Code is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Claude Code (Anthropic's CLI)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for Claude Code installation. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing Claude Code (curl ... | bash)... ${NC}"
    local claude_out claude_ec
    if [ "$QUIET" = true ]; then
      claude_out=$(curl -fsSL https://claude.ai/install.sh 2>/dev/null | bash 2>&1); claude_ec=$?
    else
      echo
      curl -fsSL https://claude.ai/install.sh | bash; claude_ec=$?
    fi
    if [ $claude_ec -eq 0 ] && command_exists claude && claude --version >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Claude Code installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Claude Code installation failed (code: $claude_ec)."
      if [ -n "$claude_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $claude_out"; fi
    fi
  else print_message "$YELLOW" "  Claude Code installation skipped."; fi
}

_install_ghostty_brew() {
  # Ghostty installation via Homebrew (macOS)
  if command_exists ghostty; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Ghostty is already installed."; fi
    return 0
  fi
  if ! command_exists brew; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Homebrew not found, cannot install Ghostty via brew."; fi
    return 1
  fi
  if ask_yes_no "  Install Ghostty (terminal emulator) using Homebrew?" "y"; then
    echo -n -e "${CYAN}    brew install --cask ghostty... ${NC}"
    if brew install --cask ghostty >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Ghostty installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    Ghostty installation failed."
    fi
  else print_message "$YELLOW" "  Ghostty installation skipped."; fi
}

_install_ghostty_arch() {
  # Ghostty installation via pacman (Arch Linux)
  if command_exists ghostty; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Ghostty is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Ghostty (terminal emulator) using pacman?" "y"; then
    local pacman_cmd="sudo pacman -S --needed --noconfirm ghostty"
    if [ "$ASSUME_YES" = false ]; then pacman_cmd="sudo pacman -S --needed ghostty"; fi
    echo -n -e "${CYAN}    pacman -S ghostty... ${NC}"
    if eval "$pacman_cmd" >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Ghostty installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    Ghostty installation failed. It may not be in the official repos yet."
      print_message "$YELLOW" "    Try: yay -S ghostty-git (AUR) or build from source: https://ghostty.org/docs/install/build"
    fi
  else print_message "$YELLOW" "  Ghostty installation skipped."; fi
}

_install_ghostty_debian() {
  # Ghostty installation guidance for Debian/Ubuntu
  # Ghostty is not in official Debian/Ubuntu repos, must be built from source or use unofficial methods
  if command_exists ghostty; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Ghostty is already installed."; fi
    return 0
  fi
  if [ "$QUIET" = false ]; then
    print_message "$YELLOW" "  Ghostty is not available in Debian/Ubuntu official repositories."
    print_message "$BLUE" "  To install Ghostty on Debian/Ubuntu:"
    print_message "$CYAN" "    Option 1: Build from source - https://ghostty.org/docs/install/build"
    print_message "$CYAN" "    Option 2: Download AppImage/binary from releases (if available)"
    print_message "$CYAN" "    Option 3: Use Nix package manager - nix-shell -p ghostty"
  fi
}

install_mac_dependencies() {
  print_header "Dependency Check for macOS"
  local all_ok=true
  if ! command_exists gcc; then
    if ask_yes_no "  Install Xcode Command Line Tools (provides GCC, Git, etc.)?" "y"; then
      if [ "$ASSUME_YES" = true ]; then print_message "$YELLOW" "    Xcode Tools install needs GUI. Run 'xcode-select --install' manually."; else
        print_message "$BLUE" "  Triggering Xcode Tools install. Follow GUI prompts."; xcode-select --install;
      fi
    fi
  elif [ "$QUIET" = false ]; then print_message "$GREEN" "  GCC (from Xcode Tools) is installed."; fi

  if ! command_exists starship; then
    if command_exists brew && ask_yes_no "  Install Starship (prompt) using Homebrew?" "y"; then
      echo -n -e "${CYAN}    brew install starship... ${NC}"; if brew install starship >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}"; else echo -e "${RED}✗${NC}"; fi
    elif [ "$QUIET" = false ] && ! command_exists brew; then print_message "$YELLOW" "  Homebrew not found, cannot install Starship via brew."; fi
  elif [ "$QUIET" = false ]; then print_message "$GREEN" "  Starship is already installed."; fi

  _install_ohmyzsh_script
  _set_zsh_default_shell
  _install_bun_script
  _install_opencode_script
  _install_claude_code_script
  _install_ghostty_brew

  if ! $all_ok; then return 1; fi
  return 0
}
install_arch_dependencies() {
  print_header "Dependency Check for Arch Linux"
  local all_ok=true
  local arch_needed_pkgs=("gcc" "zsh" "curl" "git" "unzip") pkgs_to_install_pacman=()
  for pkg in "${arch_needed_pkgs[@]}"; do
    if ! command_exists "$pkg"; then
      if ask_yes_no "  Package '$pkg' not found. Install with pacman?" "y"; then pkgs_to_install_pacman+=("$pkg"); fi
    elif [ "$QUIET" = false ]; then print_message "$GREEN" "  $pkg is available."; fi
  done
  if [ ${#pkgs_to_install_pacman[@]} -gt 0 ]; then
    local pacman_cmd="sudo pacman -S --needed --noconfirm ${pkgs_to_install_pacman[*]}"
    if [ "$ASSUME_YES" = false ]; then pacman_cmd="sudo pacman -S --needed ${pkgs_to_install_pacman[*]}"; fi
    echo -n -e "${CYAN}    pacman -S ${pkgs_to_install_pacman[*]}... ${NC}"; if eval "$pacman_cmd" >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}"; else echo -e "${RED}✗${NC}"; all_ok=false; fi
  fi

  _install_starship_via_curl_script
  _install_ohmyzsh_script
  _set_zsh_default_shell
  _install_bun_script
  _install_opencode_script
  _install_claude_code_script
  _install_ghostty_arch

  if ! $all_ok; then return 1; fi
  return 0
}
install_debian_dependencies() { 
  print_header "Installing Dependencies for Debian/Ubuntu"
  local all_ok=true

  if [ "$QUIET" = false ]; then print_message "$BLUE" "Updating package lists (sudo)..."; fi
  echo -n -e "${CYAN}Updating apt package lists... ${NC}"
  if sudo apt-get update -y >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}"; else
    echo -e "${RED}✗${NC}"; print_message "$RED" "Failed to update apt lists."; all_ok=false
  fi

  local essential_deps_script=("git" "curl" "software-properties-common" "build-essential" "zsh" "unzip") 
  local packages_to_install_apt=()
  if [ "$QUIET" = false ]; then print_message "$BLUE" "Checking core packages (git, curl, build-essential/gcc, zsh)..."; fi
  for package in "${essential_deps_script[@]}"; do
    local check_cmd="$package"; if [ "$package" = "build-essential" ]; then check_cmd="gcc"; fi
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed" && ! command_exists "$check_cmd"; then
      if ask_yes_no "  Install $package (provides $check_cmd)?" "y"; then packages_to_install_apt+=("$package"); fi
    elif [ "$QUIET" = false ]; then print_message "$GREEN" "  $package is already installed."; fi
  done
  if [ ${#packages_to_install_apt[@]} -gt 0 ]; then
    echo -n -e "${CYAN}  Installing with apt: ${packages_to_install_apt[*]}... ${NC}"
    if sudo apt-get install -y "${packages_to_install_apt[@]}" >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}"; else
      echo -e "${RED}✗${NC}"; print_message "$RED" "  Failed to install some apt packages."; all_ok=false
    fi
  fi

  local nvim_installed_path; nvim_installed_path=$(command -v nvim 2>/dev/null || true)
  local install_neovim_via_ppa=false
  if [ -n "$nvim_installed_path" ]; then
    local current_nvim_version=$($nvim_installed_path --version 2>/dev/null | head -n 1 || echo "Unknown version")
    print_message "$GREEN" "  Neovim is already installed: $current_nvim_version (at $nvim_installed_path)"
    if ask_yes_no "  Update/reinstall Neovim using the UNSTABLE PPA (ppa:neovim-ppa/unstable)?" "y"; then
      install_neovim_via_ppa=true; 
    fi
  else
    print_message "$YELLOW" "  Neovim not found."
    if ask_yes_no "  Install Neovim using the UNSTABLE PPA (ppa:neovim-ppa/unstable)?" "y"; then install_neovim_via_ppa=true; fi
  fi
  if [ "$install_neovim_via_ppa" = true ]; then
    print_message "$BLUE" "  Attempting to install/update Neovim using UNSTABLE PPA..."
    if ! command_exists add-apt-repository; then print_message "$RED" "    'add-apt-repository' (software-properties-common) not found."; else
      echo -n -e "${CYAN}    Adding Neovim UNSTABLE PPA... ${NC}"
      if sudo add-apt-repository -y ppa:neovim-ppa/unstable >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}";
        echo -n -e "${CYAN}    Updating package lists after PPA... ${NC}"; if sudo apt-get update -y >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}";
          echo -n -e "${CYAN}    Installing neovim from PPA... ${NC}"; if sudo apt-get install -y neovim >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}"; else echo -e "${RED}✗${NC}"; all_ok=false; fi
        else echo -e "${RED}✗${NC}"; all_ok=false; fi
      else echo -e "${RED}✗${NC}"; all_ok=false; fi
    fi
  fi

  _install_starship_via_curl_script
  _install_ohmyzsh_script
  _set_zsh_default_shell
  _install_bun_script
  _install_opencode_script
  _install_claude_code_script
  _install_ghostty_debian

  if ! $all_ok; then return 1; fi
  print_message "$GREEN" "Debian/Ubuntu dependency check complete."
  return 0
}
install_dependencies() { 
  local os_name_detected=""
  local os_id_like=""
  local os_id=""
  local os_uname_s
  os_uname_s=$(uname -s)

  case "$os_uname_s" in
  Darwin) os_name_detected="macOS"; install_mac_dependencies ;;
  Linux)
    if [ -f /etc/os-release ]; then
      os_id=$(. /etc/os-release && echo "$ID"); os_id_like=$(. /etc/os-release && echo "$ID_LIKE")
      local os_pretty_name; os_pretty_name=$(. /etc/os-release && echo "$PRETTY_NAME")
      if [[ "$os_id" == "debian" || "$os_id_like" == *"debian"* || "$os_id" == "ubuntu" ]]; then
        os_name_detected="Debian/Ubuntu ($os_pretty_name)"; install_debian_dependencies
      elif [[ "$os_id" == "arch" || "$os_id_like" == *"arch"* ]]; then
        os_name_detected="Arch Linux ($os_pretty_name)"; install_arch_dependencies
      else
        print_message "$RED" "Unsupported Linux distribution: $os_pretty_name (ID: $os_id)"
        print_message "$YELLOW" "Manual dependency installation may be needed."
      fi
    else
      print_message "$RED" "Unsupported Linux distribution (no /etc/os-release file found)."
    fi ;;
  *)
    print_message "$RED" "Unsupported operating system: $os_uname_s"
    ;;
  esac
  if [ "$QUIET" = false ] && [ -n "$os_name_detected" ]; then
    print_message "$GREEN" "Dependency check for $os_name_detected complete."
  fi
}

# --- Installation Summary ---
print_installation_summary() {
  if [ "$QUIET" = false ]; then
    print_header "Installation Summary"

    # Check installed tools
    local installed_tools=()
    local failed_tools=()

    command_exists starship && installed_tools+=("Starship") || failed_tools+=("Starship")
    (command_exists bun || [ -f "$HOME/.bun/bin/bun" ]) && installed_tools+=("Bun") || failed_tools+=("Bun")
    command_exists opencode && installed_tools+=("OpenCode") || failed_tools+=("OpenCode")
    command_exists claude && installed_tools+=("Claude Code") || failed_tools+=("Claude Code")
    [ -d "$HOME/.oh-my-zsh" ] && installed_tools+=("Oh My Zsh") || failed_tools+=("Oh My Zsh")
    command_exists ghostty && installed_tools+=("Ghostty") || failed_tools+=("Ghostty")

    # Check linked configs
    local linked_configs=()
    [ -L "$HOME/.config/nvim" ] && linked_configs+=("Neovim")
    [ -L "$HOME/.config/starship" ] && linked_configs+=("Starship")
    [ -L "$HOME/.tmux.conf" ] && linked_configs+=("Tmux")
    [ -L "$HOME/.zshrc" ] && linked_configs+=("Zsh")
    [ -L "$HOME/.config/opencode" ] && linked_configs+=("OpenCode")
    [ -L "$HOME/.config/ghostty" ] && linked_configs+=("Ghostty")
    [ -L "$HOME/.claude" ] && linked_configs+=("Claude")

    if [ ${#installed_tools[@]} -gt 0 ]; then
      print_message "$GREEN" "✅ Successfully installed: ${installed_tools[*]}"
    fi

    if [ ${#failed_tools[@]} -gt 0 ]; then
      print_message "$YELLOW" "⚠️  Failed to install: ${failed_tools[*]}"
    fi

    if [ ${#linked_configs[@]} -gt 0 ]; then
      print_message "$GREEN" "🔗 Linked configurations: ${linked_configs[*]}"
    fi

    echo
    print_message "$CYAN" "Next steps:"
    print_message "$CYAN" "  1. Review any errors above"
    print_message "$CYAN" "  2. Restart terminal or source configs"
    print_message "$CYAN" "  3. Set up your API keys in secrets.zsh"
  fi
}

# --- Main Script Logic ---

# Set error trapping for the main script too
set -E
trap 'echo -e "\033[0;31mERROR at line $LINENO: $BASH_COMMAND\033[0m"' ERR

if [ "$UNLINK" = true ]; then
  manage_dotfiles "unlink" 
  exit $? 
fi

if [ "$QUIET" = false ]; then
  print_header "Dotfiles Setup (Manual Symlinking)"
  print_message "$CYAN" "This script will link your dotfiles using manual symlinks."
  echo
  if [ "$INTERACTIVE" = true ] && [ "$ASSUME_YES" = false ]; then
    if ! ask_yes_no "Continue with setup (linking and/or dependency installation)?" "y"; then
      print_message "$YELLOW" "Setup cancelled."
      exit 0
    fi
  fi
fi

if [ "$LINK_ONLY" = false ]; then
  if [ "$QUIET" = false ]; then
    print_header "Dependency Installation"
    if [ "$INTERACTIVE" = true ] && [ "$ASSUME_YES" = false ]; then
      if ! ask_yes_no "Attempt to install/check system dependencies?" "y"; then
        print_message "$YELLOW" "Dependency installation skipped by user."
      else install_dependencies; fi
    else 
      if [ "$QUIET" = false ]; then print_message "$BLUE" "Checking/installing dependencies (non-interactive)..."; fi
      install_dependencies
    fi
  else install_dependencies; fi
else
  if [ "$QUIET" = false ]; then print_message "$YELLOW" "Skipping dependency installation due to --link-only flag."; fi
fi

AVAILABLE_PACKAGES_ARR=($(get_available_packages)) 
if [ ${#AVAILABLE_PACKAGES_ARR[@]} -eq 0 ]; then
  print_message "$RED" "No packages (directories like nvim, tmux, etc.) found in your dotfiles source directory: $LINK_SRC_BASE_DIR"
  print_message "$YELLOW" "Ensure this script is in the root of your dotfiles repo, and packages are top-level directories."
  exit 1
fi

echo -e "${PURPLE}DEBUG: Found packages: ${AVAILABLE_PACKAGES_ARR[*]}${NC}"

# PACKAGES_TO_PROCESS is set by -p or interactively below
if [ -z "$PACKAGES_TO_PROCESS" ]; then 
    if [ "$ASSUME_YES" = true ]; then
      PACKAGES_TO_PROCESS=$(IFS=,; echo "${AVAILABLE_PACKAGES_ARR[*]}")
      if [ "$QUIET" = false ]; then print_message "$BLUE" "Assume-yes: Selecting all available packages: $PACKAGES_TO_PROCESS"; fi
    elif [ "$INTERACTIVE" = true ]; then
      print_header "Package Selection for Linking/Unlinking"
      print_message "$BLUE" "Available packages in '$LINK_SRC_BASE_DIR':"
      for i in "${!AVAILABLE_PACKAGES_ARR[@]}"; do echo -e "  ${GREEN}$((i + 1))${NC}. ${YELLOW}${AVAILABLE_PACKAGES_ARR[$i]}${NC}"; done
      echo
      read -r -p "$(echo -e "${CYAN}Enter numbers (e.g., 1,3), 'all', or Enter for all: ${NC}")" choices_str
      if [[ -z "$choices_str" || "$choices_str" == "all" ]]; then
        PACKAGES_TO_PROCESS=$(IFS=,; echo "${AVAILABLE_PACKAGES_ARR[*]}")
        print_message "$GREEN" "Selected all packages: $PACKAGES_TO_PROCESS"
      else
        local selected_temp_arr=()
        IFS=',' read -ra choice_indices <<<"$choices_str"
        for idx_str_loop in "${choice_indices[@]}"; do
          curr_idx_str=$(echo "$idx_str_loop" | tr -d '[:space:]')
          if [[ "$curr_idx_str" =~ ^[1-9][0-9]*$ ]]; then
            item_idx_val=$((curr_idx_str - 1))
            if [[ $item_idx_val -ge 0 && $item_idx_val -lt ${#AVAILABLE_PACKAGES_ARR[@]} ]]; then selected_temp_arr+=("${AVAILABLE_PACKAGES_ARR[$item_idx_val]}"); else print_message "$YELLOW" "Warn: Invalid selection '$curr_idx_str'."; fi
          elif [ -n "$curr_idx_str" ]; then print_message "$YELLOW" "Warn: Invalid input '$curr_idx_str'."; fi
        done
        if [ ${#selected_temp_arr[@]} -gt 0 ]; then
            PACKAGES_TO_PROCESS=$(IFS=,; echo "${selected_temp_arr[*]}")
            print_message "$GREEN" "Selected packages: $PACKAGES_TO_PROCESS"
        else
            print_message "$YELLOW" "No valid packages selected."
            PACKAGES_TO_PROCESS="" 
        fi
      fi
    else 
      PACKAGES_TO_PROCESS=$(IFS=,; echo "${AVAILABLE_PACKAGES_ARR[*]}") 
      if [ "$QUIET" = false ]; then print_message "$BLUE" "Non-interactive: Selecting all available packages: $PACKAGES_TO_PROCESS"; fi
    fi
fi

echo -e "${PURPLE}DEBUG: Final packages to process: $PACKAGES_TO_PROCESS${NC}"

manage_ec=0
# Check if PACKAGES_TO_PROCESS ended up empty after interactive selection with no valid choices
if [ -z "$PACKAGES_TO_PROCESS" ] && [ "$INTERACTIVE" = true ] && [ -n "$choices_str" ] && [[ "$choices_str" != "all" ]]; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "No packages to process based on selection."; fi
elif [ -n "$PACKAGES_TO_PROCESS" ] || ([ ${#AVAILABLE_PACKAGES_ARR[@]} -gt 0 ] && ([ "$ASSUME_YES" = true ] || [ "$INTERACTIVE" = false ])); then
    # Proceed if PACKAGES_TO_PROCESS is set, or if it's empty but we default to all available
    echo -e "${PURPLE}DEBUG: Calling manage_dotfiles with 'link'${NC}"
    manage_dotfiles "link"
    manage_ec=$?
    echo -e "${PURPLE}DEBUG: manage_dotfiles returned with status $manage_ec${NC}"
else
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "No packages selected or available to process."; fi
fi

if [ "$QUIET" = false ]; then
  print_header "Setup Complete"
  if [ $manage_ec -eq 0 ]; then
      print_message "$GREEN" "Dotfiles processing finished successfully!"
  else
    print_message "$RED" "Dotfiles processing finished with errors."
  fi

  # Print installation summary
  print_installation_summary

  echo; print_message "$YELLOW" "Enjoy your environment! 🎉"
fi

# Disable error trap before exiting
trap - ERR

exit $manage_ec
