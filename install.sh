#!/usr/bin/env bash

echo -e "\033[0;36mDEBUG: install.sh script interpreter has started.\033[0m"

# --- Robust SCRIPT_DIR Initialization ---
set +e
SCRIPT_DIR_RAW="${BASH_SOURCE[0]}"
if [[ -z "$SCRIPT_DIR_RAW" ]]; then
  echo -e "\033[0;31mFATAL ERROR: BASH_SOURCE[0] is empty. Cannot determine script directory.\033[0m" >&2
  exit 1
fi
SCRIPT_DIR_TEMP="$(cd "$(dirname "$SCRIPT_DIR_RAW")" >/dev/null 2>&1 && pwd)"
SCRIPT_DIR_EXIT_CODE=$?
set -e
if [ $SCRIPT_DIR_EXIT_CODE -ne 0 ] || [ -z "$SCRIPT_DIR_TEMP" ] || [ ! -d "$SCRIPT_DIR_TEMP" ]; then
  echo -e "\033[0;31mFATAL ERROR: Failed to determine script directory.\033[0m" >&2
  exit 1
fi
SCRIPT_DIR="$SCRIPT_DIR_TEMP"
echo -e "\033[0;36mDEBUG: Script directory determined as: $SCRIPT_DIR\033[0m"
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
  echo "  -q, --quiet          Minimize output (stow errors will still be shown)"
  echo "  -p, --packages       Comma-separated list of packages to link/unlink (default: all)"
  echo
  echo "Example:"
  echo "  ./install.sh -d ~/my-dotfiles -p nvim,tmux"
  echo "  ./install.sh -u       # Unlink all dotfiles"
  echo "  ./install.sh -l       # Link dotfiles, skip dependency installation"
}

# Parse arguments
DOTFILES_DIR="$SCRIPT_DIR"
UNLINK=false
ASSUME_YES=false
INTERACTIVE=false
QUIET=false
PACKAGES=""
LINK_ONLY=false

if [ -t 0 ] && [ -t 1 ]; then INTERACTIVE=true; fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -h | --help)
    show_help
    exit 0
    ;;
  -d | --dotfiles-dir)
    DOTFILES_DIR="$2"
    shift
    shift
    ;;
  -l | --link-only)
    LINK_ONLY=true
    shift
    ;;
  -u | --unlink)
    UNLINK=true
    shift
    ;;
  -y | --yes)
    ASSUME_YES=true
    INTERACTIVE=false
    shift
    ;;
  -i | --interactive)
    INTERACTIVE=true
    ASSUME_YES=false
    shift
    ;;
  -q | --quiet)
    QUIET=true
    INTERACTIVE=false
    shift
    ;;
  -p | --packages)
    PACKAGES="$2"
    shift
    shift
    ;;
  *)
    print_message "$RED" "Unknown option: $1"
    show_help
    exit 1
    ;;
  esac
done

if [ -d "$DOTFILES_DIR" ]; then DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"; else
  print_message "$RED" "Error: Dotfiles directory not found at '$DOTFILES_DIR'"
  exit 1
fi
STOW_DIR="$DOTFILES_DIR/stow"
if [ ! -d "$STOW_DIR" ]; then
  print_message "$RED" "Error: Stow directory not found at: $STOW_DIR"
  exit 1
fi

get_available_packages() { find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort; }

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

unlink_dotfiles() {
  print_header "Unlinking Dotfiles"
  if ! command_exists stow; then
    print_message "$RED" "Error: GNU stow not found."
    exit 1
  fi
  local pkgs_arr=()
  if [ -n "$PACKAGES" ]; then IFS=',' read -ra pkgs_arr <<<"$PACKAGES"; else
    local all_dirs=()
    while IFS= read -r -d $'\0' dir; do all_dirs+=("$(basename "$dir")"); done < <(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    pkgs_arr=("${all_dirs[@]}")
  fi
  if [ ${#pkgs_arr[@]} -eq 0 ]; then
    print_message "$YELLOW" "No packages to unlink."
    return 0
  fi
  if [ "$QUIET" = false ]; then print_message "$BLUE" "Unlinking: ${pkgs_arr[*]}"; fi
  local succ=0 fail=0 fail_pkgs_arr=()
  for pkg_name in "${pkgs_arr[@]}"; do
    if [ ! -d "$STOW_DIR/$pkg_name" ]; then
      print_message "$YELLOW" "Pkg dir $STOW_DIR/$pkg_name not found. Skipping."
      continue
    fi
    if [ "$QUIET" = false ]; then echo -n -e "${CYAN}Unlinking $pkg_name... ${NC}"; fi
    local stow_out stow_ec
    stow_out=$(stow -vD "$pkg_name" --dir="$STOW_DIR" --target="$HOME" 2>&1)
    stow_ec=$?
    if [ $stow_ec -eq 0 ]; then
      if [ "$QUIET" = false ]; then echo -e "${GREEN}✓${NC}"; fi
      ((succ++))
    else
      if [ "$QUIET" = false ]; then echo -e "${RED}✗${NC}"; fi
      print_message "$RED" "❌ Fail unlink '$pkg_name' (code: $stow_ec)"
      if [ -n "$stow_out" ]; then
        print_message "$RED" "Stow output:"
        echo -e "${GRAY}$(echo "$stow_out" | sed 's/^/  /')\n${NC}"
      fi
      ((fail++))
      fail_pkgs_arr+=("$pkg_name")
    fi
  done
  echo
  print_message "$BLUE" "Unlink Summary"
  print_message "$GREEN" "Success: $succ"
  if [ $fail -gt 0 ]; then
    print_message "$RED" "Failed: $fail (${fail_pkgs_arr[*]}). Check output."
    return 1
  fi
  if [ $succ -gt 0 ] && [ $fail -eq 0 ]; then print_message "$GREEN" "✨ All unlinked!"; elif [ $succ -eq 0 ] && [ $fail -eq 0 ]; then print_message "$YELLOW" "No packages unlinked."; fi
  return 0
}

link_dotfiles() {
  local pkgs_to_link_str="$1"
  print_header "Linking Dotfiles (Pre-clear & Re-stow)"
  if ! command_exists stow; then
    print_message "$RED" "Error: GNU stow not found."
    exit 1
  fi

  if [ -f "$SCRIPT_DIR/link_files.sh" ]; then
    print_message "$BLUE" "Using external link_files.sh..."
    local link_args=""
    if [ -n "$DOTFILES_DIR" ]; then link_args+=" --dotfiles-dir \"$DOTFILES_DIR\""; fi
    if [ "$ASSUME_YES" = true ]; then link_args+=" --force"; fi
    if [ "$QUIET" = true ]; then link_args+=" --quiet"; fi
    if [ -n "$pkgs_to_link_str" ]; then link_args+=" --packages \"$pkgs_to_link_str\""; fi
    if bash -c "\"$SCRIPT_DIR/link_files.sh\" $link_args"; then
      print_message "$GREEN" "External script OK."
      return 0
    else
      print_message "$RED" "External script FAIL."
      return 1
    fi
  fi

  if [ "$QUIET" = false ]; then print_message "$BLUE" "Using built-in stow (pre-clear & re-stow -R)..."; fi
  local pkgs_to_link_arr=()
  if [ -n "$pkgs_to_link_str" ]; then IFS=',' read -ra pkgs_to_link_arr <<<"$pkgs_to_link_str"; else
    local all_dirs_loc=()
    while IFS= read -r -d $'\0' dir_loc; do all_dirs_loc+=("$(basename "$dir_loc")"); done < <(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    pkgs_to_link_arr=("${all_dirs_loc[@]}")
  fi
  if [ ${#pkgs_to_link_arr[@]} -eq 0 ]; then
    print_message "$YELLOW" "No packages to link."
    return 0
  fi
  if [ "$QUIET" = false ]; then print_message "$BLUE" "Re-stowing: ${pkgs_to_link_arr[*]}"; fi

  local succ_cnt=0 fail_cnt=0 fail_pkgs_list=() backup_made_globally=false
  local ts=$(date +%Y%m%d_%H%M%S) main_backup_basedir="$HOME/.dotfiles_backup/$ts"

  for pkg_name_loop in "${pkgs_to_link_arr[@]}"; do
    local pkg_stow_src_dir="$STOW_DIR/$pkg_name_loop"
    if [ ! -d "$pkg_stow_src_dir" ]; then
      print_message "$YELLOW" "Pkg dir '$pkg_stow_src_dir' not found. Skipping."
      continue
    fi
    if [ "$QUIET" = false ]; then echo -e "${CYAN}Processing package '$pkg_name_loop'...${NC}"; fi
    local pre_clear_ok=true first_conflict_header_printed=false
    if [ "$QUIET" = false ]; then print_message "$BLUE" "  Performing pre-stow cleanup check for '$pkg_name_loop':"; fi
    local find_results_file
    find_results_file=$(mktemp)
    find "$pkg_stow_src_dir" -depth -print0 >"$find_results_file"
    while IFS= read -r -d $'\0' src_item_abs_path; do
      if [[ "$src_item_abs_path" == "$pkg_stow_src_dir" ]]; then continue; fi
      local rel_to_pkg_root="${src_item_abs_path#$pkg_stow_src_dir/}"
      local target_in_home="$HOME/$rel_to_pkg_root"
      if [ -e "$target_in_home" ] || [ -L "$target_in_home" ]; then
        local is_correct_link=false
        if [ -L "$target_in_home" ]; then
          local link_points_to
          link_points_to=$(readlink -f "$target_in_home" 2>/dev/null || true)
          if [[ "$link_points_to" == "$src_item_abs_path" ]]; then is_correct_link=true; fi
        fi
        if ! $is_correct_link; then
          if [ "$QUIET" = false ] && ! $first_conflict_header_printed; then
            print_message "$YELLOW" "    Found items in '$HOME' conflicting with '$pkg_name_loop' contents:"
            first_conflict_header_printed=true
          fi
          local conflict_desc="item"
          if [ -L "$target_in_home" ]; then conflict_desc="symlink (to: $(readlink "$target_in_home" 2>/dev/null || echo "broken"))"; fi
          if [ -d "$target_in_home" ] && [ ! -L "$target_in_home" ]; then conflict_desc="directory"; fi
          if [ -f "$target_in_home" ] && [ ! -L "$target_in_home" ]; then conflict_desc="file"; fi
          if ask_yes_no "      Target '$target_in_home' ($conflict_desc) conflicts. Backup & remove it?" "y"; then
            backup_made_globally=true
            local item_backup_parent="$main_backup_basedir/$pkg_name_loop/$(dirname "$rel_to_pkg_root")"
            mkdir -p "$item_backup_parent"
            local item_backup_target="$main_backup_basedir/$pkg_name_loop/$rel_to_pkg_root"
            if [ "$QUIET" = false ]; then print_message "$BLUE" "        Backing up '$target_in_home' to '$item_backup_target'"; fi
            if cp -aL "$target_in_home" "$item_backup_target"; then if [ "$QUIET" = false ]; then print_message "$GRAY" "          Backed up."; fi; else
              print_message "$RED" "        ERROR: Failed to backup '$target_in_home'."
              pre_clear_ok=false
            fi
            if $pre_clear_ok; then
              if [ "$QUIET" = false ]; then print_message "$BLUE" "        Removing '$target_in_home'"; fi
              if rm -rf "$target_in_home"; then if [ "$QUIET" = false ]; then print_message "$GRAY" "          Removed."; fi; else
                print_message "$RED" "        ERROR: Failed to remove '$target_in_home'."
                pre_clear_ok=false
              fi
            fi
          else
            if [ "$QUIET" = false ]; then print_message "$YELLOW" "      Skipping removal of '$target_in_home'. Stow will likely fail."; fi
            pre_clear_ok=false
          fi
        fi
      fi
      if ! $pre_clear_ok; then break; fi
    done < <(cat "$find_results_file" | sort -zr)
    rm -f "$find_results_file"
    if ! $pre_clear_ok; then
      if [ "$QUIET" = false ]; then print_message "$RED" "  Pre-clear for '$pkg_name_loop' failed/aborted. Skipping stow."; fi
      ((fail_cnt++))
      fail_pkgs_list+=("$pkg_name_loop (pre-clear failed)")
      continue
    fi
    if [ "$QUIET" = false ] && $first_conflict_header_printed; then echo; fi
    if [ "$QUIET" = false ]; then echo -n -e "${CYAN}  Attempting to re-stow '$pkg_name_loop'... ${NC}"; fi
    local stow_out_val stow_ec_val
    stow_out_val=$(stow -vR "$pkg_name_loop" --dir="$STOW_DIR" --target="$HOME" 2>&1)
    stow_ec_val=$?
    if [ $stow_ec_val -eq 0 ]; then
      if [ "$QUIET" = false ]; then echo -e "${GREEN}✓ Re-stowed${NC}"; fi
      ((succ_cnt++))
    else
      if [ "$QUIET" = false ]; then echo -e "${RED}✗ Re-stow Failed${NC}"; fi
      print_message "$RED" "❌ Failed to re-stow '$pkg_name_loop' (code: $stow_ec_val)"
      if [ -n "$stow_out_val" ]; then
        print_message "$RED" "  Stow output:"
        echo -e "${GRAY}$(echo "$stow_out_val" | sed 's/^    /')\n${NC}"
      fi
      ((fail_cnt++))
      fail_pkgs_list+=("$pkg_name_loop")
    fi
  done
  echo
  print_message "$BLUE" "Link Summary"
  print_message "$GREEN" "Success: $succ_cnt"
  if [ $fail_cnt -gt 0 ]; then print_message "$RED" "Failed: $fail_cnt (${fail_pkgs_list[*]}). Check output."; fi
  if [ "$backup_made_globally" = true ]; then if [ -d "$main_backup_basedir" ] && [ "$(ls -A "$main_backup_basedir")" ]; then
    echo
    print_message "$BLUE" "Backups created in $main_backup_basedir"
  fi; fi
  if [ $fail_cnt -eq 0 ]; then
    if [ $succ_cnt -gt 0 ]; then print_message "$GREEN" "✨ All re-stowed!"; elif [ ${#pkgs_to_link_arr[@]} -gt 0 ]; then print_message "$YELLOW" "No packages re-stowed."; fi
    return 0
  else
    print_message "$RED" "⚠️ Some packages failed. Review logs. Manually remove conflicting non-symlinked DIRS if needed."
    return 1
  fi
}

# Function to install dependencies for macOS (Simplified Stub)
install_mac_dependencies() {
  print_header "Dependency Check for macOS"
  if ! command_exists stow; then
    print_message "$RED" "GNU Stow not found. Please install stow (e.g., using Homebrew: 'brew install stow')."
    return 1
  fi
  print_message "$GREEN" "Stow is installed."
  print_message "$YELLOW" "Other dependency installations for macOS are not handled by this script."
  return 0
}

# Function to install dependencies for Arch Linux (Simplified Stub)
install_arch_dependencies() {
  print_header "Dependency Check for Arch Linux"
  if ! command_exists stow; then
    print_message "$RED" "GNU Stow not found. Please install stow (e.g., 'sudo pacman -S stow')."
    return 1
  fi
  print_message "$GREEN" "Stow is installed."
  print_message "$YELLOW" "Other dependency installations for Arch Linux are not handled by this script."
  return 0
}

# Function to install dependencies for Debian/Ubuntu (Focus on Neovim PPA - UNSTABLE)
install_debian_dependencies() {
  print_header "Installing Dependencies for Debian/Ubuntu"

  if [ "$QUIET" = false ]; then
    print_message "$BLUE" "Updating package lists (sudo will be required)..."
  fi
  echo -n -e "${CYAN}Updating apt package lists... ${NC}"
  if sudo apt-get update -y >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
    print_message "$RED" "Failed to update apt lists. Some installations may fail."
  fi

  local essential_deps_for_script=("stow" "git" "curl" "software-properties-common") # software-properties-common for add-apt-repository
  local packages_to_install_apt=()

  if [ "$QUIET" = false ]; then print_message "$BLUE" "Checking essential packages (stow, git, curl, software-properties-common)..."; fi
  for package in "${essential_deps_for_script[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
      if ask_yes_no "  Install $package (essential for script operation/Neovim PPA)?" "y"; then
        packages_to_install_apt+=("$package")
      else
        print_message "$RED" "  $package is required. Aborting dependency installation."
        return 1 # Critical dependency declined
      fi
    else
      if [ "$QUIET" = false ]; then print_message "$GREEN" "  $package is already installed."; fi
    fi
  done

  # Install any accumulated essential packages first
  if [ ${#packages_to_install_apt[@]} -gt 0 ]; then
    if [ "$QUIET" = false ]; then print_message "$BLUE" "  Installing with apt: ${packages_to_install_apt[*]}"; fi
    echo -n -e "${CYAN}  Installing selected apt packages... ${NC}"
    if sudo apt-get install -y "${packages_to_install_apt[@]}" >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "  Failed to install some essential apt packages. Neovim PPA addition might fail."
    fi
  fi
  packages_to_install_apt=() # Reset for Neovim

  # --- Install Neovim using PPA (UNSTABLE) ---
  local nvim_installed_path
  nvim_installed_path=$(command -v nvim 2>/dev/null || true)
  local install_neovim_via_ppa=false

  if [ -n "$nvim_installed_path" ]; then
    local current_nvim_version=$($nvim_installed_path --version 2>/dev/null | head -n 1 || echo "Unknown version")
    print_message "$GREEN" "  Neovim is already installed: $current_nvim_version (at $nvim_installed_path)"
    if ask_yes_no "  Update/reinstall Neovim using the UNSTABLE PPA (ppa:neovim-ppa/unstable)?" "y"; then
      install_neovim_via_ppa=true
    else
      print_message "$YELLOW" "  Keeping existing Neovim version."
    fi
  else
    print_message "$YELLOW" "  Neovim not found."
    if ask_yes_no "  Install Neovim using the UNSTABLE PPA (ppa:neovim-ppa/unstable)?" "y"; then
      install_neovim_via_ppa=true
    else
      print_message "$YELLOW" "  Neovim installation skipped."
    fi
  fi

  if [ "$install_neovim_via_ppa" = true ]; then
    print_message "$BLUE" "  Attempting to install/update Neovim using UNSTABLE PPA..."
    echo -n -e "${CYAN}    Adding Neovim UNSTABLE PPA (ppa:neovim-ppa/unstable)... ${NC}"
    if sudo add-apt-repository -y ppa:neovim-ppa/unstable >/dev/null 2>&1; then # CHANGED HERE
      echo -e "${GREEN}✓${NC}"
      echo -n -e "${CYAN}    Updating package lists after adding PPA... ${NC}"
      if sudo apt-get update -y >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        echo -n -e "${CYAN}    Installing neovim from PPA... ${NC}"
        if sudo apt-get install -y neovim >/dev/null 2>&1; then
          echo -e "${GREEN}✓${NC}"
          print_message "$GREEN" "    Neovim installed/updated successfully from UNSTABLE PPA."
        else
          echo -e "${RED}✗${NC}"
          print_message "$RED" "    ERROR: Failed to install neovim from PPA after update."
        fi
      else
        echo -e "${RED}✗${NC}"
        print_message "$RED" "    ERROR: Failed to update package lists after adding Neovim PPA."
      fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    ERROR: Failed to add Neovim UNSTABLE PPA. Make sure 'software-properties-common' is installed."
    fi
  fi
  # --- End of Neovim PPA Install ---

  print_message "$GREEN" "Debian/Ubuntu dependency check complete."
  return 0
}

# Function to install dependencies based on OS
install_dependencies() {
  local os_name_detected=""
  local os_id_like=""
  local os_id=""
  local os_uname_s
  os_uname_s=$(uname -s)

  case "$os_uname_s" in
  Darwin)
    os_name_detected="macOS"
    install_mac_dependencies
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      os_id=$(. /etc/os-release && echo "$ID")
      os_id_like=$(. /etc/os-release && echo "$ID_LIKE")
      local os_pretty_name
      os_pretty_name=$(. /etc/os-release && echo "$PRETTY_NAME")

      if [[ "$os_id" == "debian" ]] || [[ "$os_id_like" == *"debian"* ]] || [[ "$os_id" == "ubuntu" ]]; then
        os_name_detected="Debian/Ubuntu ($os_pretty_name)"
        install_debian_dependencies
      elif [[ "$os_id" == "arch" ]] || [[ "$os_id_like" == *"arch"* ]]; then
        os_name_detected="Arch Linux ($os_pretty_name)"
        install_arch_dependencies
      else
        print_message "$RED" "Unsupported Linux distribution: $os_pretty_name (ID: $os_id)"
        print_message "$YELLOW" "Dependency installation will be skipped. Please install 'stow' manually if needed."
        return 1
      fi
    else
      print_message "$RED" "Unsupported Linux distribution (no /etc/os-release file found)."
      print_message "$YELLOW" "Dependency installation will be skipped. Please install 'stow' manually if needed."
      return 1
    fi
    ;;
  *)
    print_message "$RED" "Unsupported operating system: $os_uname_s"
    print_message "$YELLOW" "Dependency installation will be skipped. Please install 'stow' manually if needed."
    return 1
    ;;
  esac
  if [ "$QUIET" = false ] && [ -n "$os_name_detected" ]; then
    print_message "$GREEN" "Dependency check for $os_name_detected complete."
  fi
}

# --- Main Script Logic ---

if [ "$UNLINK" = true ]; then
  unlink_dotfiles
  exit $?
fi

if [ "$QUIET" = false ]; then
  print_header "Dotfiles Setup"
  print_message "$CYAN" "This script will link your dotfiles using GNU stow."
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
      if ! ask_yes_no "Attempt to install/check system dependencies (e.g., stow, Neovim via PPA on Debian/Ubuntu)?" "y"; then
        print_message "$YELLOW" "Dependency installation skipped by user."
      else
        install_dependencies
      fi
    else
      if [ "$QUIET" = false ]; then print_message "$BLUE" "Checking/installing dependencies (non-interactive)..."; fi
      install_dependencies
    fi
  else
    install_dependencies
  fi
else
  if [ "$QUIET" = false ]; then
    print_message "$YELLOW" "Skipping dependency installation due to --link-only flag."
  fi
fi

AVAILABLE_PACKAGES_ARR=($(get_available_packages))
if [ ${#AVAILABLE_PACKAGES_ARR[@]} -eq 0 ]; then
  print_message "$RED" "No packages (subdirectories) found in your stow directory: $STOW_DIR"
  if [ "$LINK_ONLY" = true ] || { [ "$LINK_ONLY" = false ] && [ ${#SELECTED_PACKAGES_ARR[@]} -eq 0 ]; }; then
    exit 1
  fi
fi

SELECTED_PACKAGES_ARR=()
if [ ${#AVAILABLE_PACKAGES_ARR[@]} -gt 0 ]; then
  if [ -n "$PACKAGES" ]; then
    IFS=',' read -ra SELECTED_PACKAGES_ARR <<<"$PACKAGES"
    temp_valid=()
    for pkg_s in "${SELECTED_PACKAGES_ARR[@]}"; do
      is_v=false
      for pkg_a in "${AVAILABLE_PACKAGES_ARR[@]}"; do if [[ "$pkg_s" == "$pkg_a" ]]; then
        temp_valid+=("$pkg_s")
        is_v=true
        break
      fi; done
      if ! $is_v; then print_message "$YELLOW" "Warn: Pkg '$pkg_s' not in $STOW_DIR. Ignoring."; fi
    done
    SELECTED_PACKAGES_ARR=("${temp_valid[@]}")
    if [ ${#SELECTED_PACKAGES_ARR[@]} -eq 0 ] && [ -n "$PACKAGES" ]; then
      print_message "$RED" "None of specified packages ($PACKAGES) found."
      print_message "$BLUE" "Available: ${AVAILABLE_PACKAGES_ARR[*]}"
      exit 1
    fi
    if [ "$QUIET" = false ] && [ ${#SELECTED_PACKAGES_ARR[@]} -gt 0 ]; then print_message "$BLUE" "Selected from cmd: ${SELECTED_PACKAGES_ARR[*]}"; fi
  else
    if [ "$ASSUME_YES" = true ]; then
      SELECTED_PACKAGES_ARR=("${AVAILABLE_PACKAGES_ARR[@]}")
      if [ "$QUIET" = false ]; then print_message "$BLUE" "Assume-yes: Selecting all available packages for linking."; fi
    elif [ "$INTERACTIVE" = true ]; then
      print_header "Package Selection for Linking"
      print_message "$BLUE" "Available in '$STOW_DIR':"
      for i in "${!AVAILABLE_PACKAGES_ARR[@]}"; do echo -e "  ${GREEN}$((i + 1))${NC}. ${YELLOW}${AVAILABLE_PACKAGES_ARR[$i]}${NC}"; done
      echo
      read -r -p "$(echo -e "${CYAN}Enter numbers (e.g., 1,3), 'all', or Enter for all to link: ${NC}")" choices_str
      if [[ -z "$choices_str" || "$choices_str" == "all" ]]; then
        SELECTED_PACKAGES_ARR=("${AVAILABLE_PACKAGES_ARR[@]}")
        print_message "$GREEN" "Selected all packages for linking."
      else
        IFS=',' read -ra choice_indices <<<"$choices_str"
        for idx_str_loop in "${choice_indices[@]}"; do
          curr_idx_str=$(echo "$idx_str_loop" | tr -d '[:space:]')
          if [[ "$curr_idx_str" =~ ^[1-9][0-9]*$ ]]; then
            item_idx_val=$((curr_idx_str - 1))
            if [[ $item_idx_val -ge 0 && $item_idx_val -lt ${#AVAILABLE_PACKAGES_ARR[@]} ]]; then SELECTED_PACKAGES_ARR+=("${AVAILABLE_PACKAGES_ARR[$item_idx_val]}"); else print_message "$YELLOW" "Warn: Invalid selection '$curr_idx_str'."; fi
          elif [ -n "$curr_idx_str" ]; then print_message "$YELLOW" "Warn: Invalid input '$curr_idx_str'."; fi
        done
        SELECTED_PACKAGES_ARR=($(echo "${SELECTED_PACKAGES_ARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
      fi
    else
      SELECTED_PACKAGES_ARR=("${AVAILABLE_PACKAGES_ARR[@]}")
      if [ "$QUIET" = false ]; then print_message "$BLUE" "Non-interactive: Selecting all available packages for linking."; fi
    fi
  fi
fi

link_ec=0
if [ ${#SELECTED_PACKAGES_ARR[@]} -gt 0 ]; then
  if [ "$QUIET" = false ]; then print_message "$GREEN" "Packages to link: ${SELECTED_PACKAGES_ARR[*]}"; fi
  PACKAGES_TO_PROCESS_STR=$(
    IFS=,
    echo "${SELECTED_PACKAGES_ARR[*]}"
  )
  link_dotfiles "$PACKAGES_TO_PROCESS_STR"
  link_ec=$?
elif [ ${#AVAILABLE_PACKAGES_ARR[@]} -gt 0 ] && [ -z "$PACKAGES" ] && [ "$INTERACTIVE" = true ] && [ ${#SELECTED_PACKAGES_ARR[@]} -eq 0 ]; then
  if [ "$QUIET" = false ]; then print_message "$YELLOW" "No packages selected for linking."; fi
elif [ ${#AVAILABLE_PACKAGES_ARR[@]} -eq 0 ]; then
  :
else
  if [ "$QUIET" = false ]; then print_message "$YELLOW" "No packages to link."; fi
fi

if [ "$QUIET" = false ]; then
  print_header "Setup Complete"
  if [ $link_ec -eq 0 ]; then
    if [ ${#SELECTED_PACKAGES_ARR[@]} -gt 0 ] || ([ ${#AVAILABLE_PACKAGES_ARR[@]} -gt 0 ] && [ -z "$PACKAGES" ] && [ "$ASSUME_YES" = true ]); then
      print_message "$GREEN" "Dotfiles linking process finished successfully!"
    elif [ ${#AVAILABLE_PACKAGES_ARR[@]} -eq 0 ]; then
      print_message "$YELLOW" "No dotfiles packages found to link."
    else
      print_message "$YELLOW" "No dotfiles selected for linking."
    fi
  else
    print_message "$RED" "Dotfiles linking process finished with errors."
  fi
  echo
  print_message "$CYAN" "Next steps:"
  print_message "$CYAN" "  1. Review any output above for errors or warnings."
  print_message "$CYAN" "  2. If stow failed on DIRS, manually back them up (e.g., 'mv ~/.config/nvim ~/.config/nvim.bak') & re-run."
  print_message "$CYAN" "  3. Restart your terminal or source relevant shell configuration files if needed."
  echo
  print_message "$YELLOW" "Enjoy your environment! 🎉"
fi

exit $link_ec
