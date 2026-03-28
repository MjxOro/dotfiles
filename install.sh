#!/usr/bin/env bash
#
# Dotfiles Installation Script
# Modularized version - sources organized submodules from lib/, cli/, packages/, installers/, distro/
#

# =============================================================================
# Bash Version Check
# =============================================================================

if [[ "${BASH_VERSION}" < "4.0" ]]; then
  echo "Error: Bash 4.0+ required. Current: ${BASH_VERSION}"
  exit 1
fi

# Enable debug mode if VERBOSE=1
if [[ "${VERBOSE:-0}" == "1" ]]; then
  echo -e "\033[0;36mDEBUG: install.sh script interpreter has started.\033[0m"
fi

# =============================================================================
# Module Loading
# =============================================================================

# Source path resolution first (needed for finding other modules)
source "${BASH_SOURCE[0]%/*}/lib/paths.sh" 2>/dev/null || {
  # Fallback: try relative path
  source "$(dirname "$0")/lib/paths.sh" 2>/dev/null || {
    echo -e "\033[0;31mFATAL ERROR: Cannot load lib/paths.sh\033[0m" >&2
    exit 1
  }
}

# Core utilities (logging must come before others)
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"

# CLI handling
source "$SCRIPT_DIR/cli/args.sh"
source "$SCRIPT_DIR/cli/help.sh"

# Installers (order matters for dependencies)
source "$SCRIPT_DIR/installers/core.sh"
source "$SCRIPT_DIR/installers/devtools.sh"
source "$SCRIPT_DIR/installers/lazyvim.sh"

# Package management
source "$SCRIPT_DIR/packages/discovery.sh"
source "$SCRIPT_DIR/packages/operations.sh"
source "$SCRIPT_DIR/packages/manager.sh"

# OS-specific distribution handlers
source "$SCRIPT_DIR/distro/macos.sh"
source "$SCRIPT_DIR/distro/arch.sh"
source "$SCRIPT_DIR/distro/debian.sh"
source "$SCRIPT_DIR/distro/dispatcher.sh"

# Summary for end-of-installation report
source "$SCRIPT_DIR/lib/summary.sh"

# =============================================================================
# Interactive Package Selection
# =============================================================================

ask_yes_no() {
  local prompt_msg="$1"
  local ans_default="${2:-y}"
  local prompt_ind

  if [ "$ASSUME_YES" = true ]; then
    return 0
  fi

  if [ "$INTERACTIVE" = false ]; then
    if [ "$ans_default" = "y" ]; then
      return 0
    else
      return 1
    fi
  fi

  if [ "$ans_default" = "y" ]; then
    prompt_ind="[Y/n]"
  else
    prompt_ind="[y/N]"
  fi

  while true; do
    read -r -p "$(echo -e "${YELLOW}${prompt_msg} ${prompt_ind} ${NC}")" yn_ans
    yn_ans=$(echo "$yn_ans" | tr '[:upper:]' '[:lower:]')
    case $yn_ans in
    y | yes) return 0 ;;
    n | no) return 1 ;;
    "")
      if [ "$ans_default" = "y" ]; then
        return 0
      else
        return 1
      fi
      ;;
    *) print_message "$RED" "Please answer 'yes' or 'no'." ;;
    esac
  done
}

# =============================================================================
# Main Script Logic
# =============================================================================

# Parse arguments first
parse_arguments "$@"

# Validate and set DOTFILES_DIR
if [ -d "$DOTFILES_DIR" ]; then
  DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"
else
  print_message "$RED" "Error: Dotfiles directory not found at '$DOTFILES_DIR'"
  exit 1
fi

export DOTFILES_DIR
LINK_SRC_BASE_DIR="$DOTFILES_DIR"

if [ ! -d "$LINK_SRC_BASE_DIR" ]; then
  print_message "$RED" "Error: Source base directory for packages not found at: $LINK_SRC_BASE_DIR"
  exit 1
fi

# Set error trapping for the main script
set -E
trap 'echo -e "\033[0;31mERROR at line $LINENO: $BASH_COMMAND\033[0m"' ERR

# =============================================================================
# Unlink Mode
# =============================================================================

if [ "$UNLINK" = true ]; then
  manage_dotfiles "unlink"
  exit $?
fi

# =============================================================================
# Introduction
# =============================================================================

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

# =============================================================================
# Dependency Installation
# =============================================================================

if [ "$LINK_ONLY" = false ]; then
  if [ "$QUIET" = false ]; then
    print_header "Dependency Installation"
    if [ "$INTERACTIVE" = true ] && [ "$ASSUME_YES" = false ]; then
      if ! ask_yes_no "Attempt to install/check system dependencies?" "y"; then
        print_message "$YELLOW" "Dependency installation skipped by user."
      else
        install_dependencies
      fi
    else
      print_message "$BLUE" "Checking/installing dependencies (non-interactive)..."
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

# =============================================================================
# Package Discovery and Selection
# =============================================================================

AVAILABLE_PACKAGES_ARR=($(get_available_packages))

if [ ${#AVAILABLE_PACKAGES_ARR[@]} -eq 0 ]; then
  print_message "$RED" "No packages (directories like nvim, tmux, etc.) found in your dotfiles source directory: $LINK_SRC_BASE_DIR"
  print_message "$YELLOW" "Ensure this script is in the root of your dotfiles repo, and packages are top-level directories."
  exit 1
fi

if [ "$VERBOSE" = "1" ]; then
  echo -e "${PURPLE}DEBUG: Found packages: ${AVAILABLE_PACKAGES_ARR[*]}${NC}"
fi

# PACKAGES_TO_PROCESS is set by -p or interactively below
if [ -z "$PACKAGES_TO_PROCESS" ]; then
  if [ "$ASSUME_YES" = true ]; then
    PACKAGES_TO_PROCESS=$(IFS=,; echo "${AVAILABLE_PACKAGES_ARR[*]}")
    if [ "$QUIET" = false ]; then
      print_message "$BLUE" "Assume-yes: Selecting all available packages: $PACKAGES_TO_PROCESS"
    fi
  elif [ "$INTERACTIVE" = true ]; then
    print_header "Package Selection for Linking/Unlinking"
    print_message "$BLUE" "Available packages in '$LINK_SRC_BASE_DIR':"
    for i in "${!AVAILABLE_PACKAGES_ARR[@]}"; do
      echo -e "  ${GREEN}$((i + 1))${NC}. ${YELLOW}${AVAILABLE_PACKAGES_ARR[$i]}${NC}"
    done
    echo
    read -r -p "$(echo -e "${CYAN}Enter numbers (e.g., 1,3), 'all', or Enter for all: ${NC}")" choices_str

    if [[ -z "$choices_str" || "$choices_str" == "all" ]]; then
      PACKAGES_TO_PROCESS=$(IFS=,; echo "${AVAILABLE_PACKAGES_ARR[*]}")
      print_message "$GREEN" "Selected all packages: $PACKAGES_TO_PROCESS"
    else
      selected_temp_arr=()
      IFS=',' read -ra choice_indices <<<"$choices_str"
      for idx_str_loop in "${choice_indices[@]}"; do
        curr_idx_str=$(echo "$idx_str_loop" | tr -d '[:space:]')
        if [[ "$curr_idx_str" =~ ^[1-9][0-9]*$ ]]; then
          item_idx_val=$((curr_idx_str - 1))
          if [[ $item_idx_val -ge 0 && $item_idx_val -lt ${#AVAILABLE_PACKAGES_ARR[@]} ]]; then
            selected_temp_arr+=("${AVAILABLE_PACKAGES_ARR[$item_idx_val]}")
          else
            print_message "$YELLOW" "Warn: Invalid selection '$curr_idx_str'."
          fi
        elif [ -n "$curr_idx_str" ]; then
          print_message "$YELLOW" "Warn: Invalid input '$curr_idx_str'."
        fi
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
    if [ "$QUIET" = false ]; then
      print_message "$BLUE" "Non-interactive: Selecting all available packages: $PACKAGES_TO_PROCESS"
    fi
  fi
fi

if [ "$VERBOSE" = "1" ]; then
  echo -e "${PURPLE}DEBUG: Final packages to process: $PACKAGES_TO_PROCESS${NC}"
fi

# =============================================================================
# Execute Dotfile Management
# =============================================================================

manage_ec=0

# Check if PACKAGES_TO_PROCESS ended up empty after interactive selection with no valid choices
if [ -z "$PACKAGES_TO_PROCESS" ] && [ "$INTERACTIVE" = true ] && [ -n "$choices_str" ] && [[ "$choices_str" != "all" ]]; then
  if [ "$QUIET" = false ]; then
    print_message "$YELLOW" "No packages to process based on selection."
  fi
elif [ -n "$PACKAGES_TO_PROCESS" ] || ([ ${#AVAILABLE_PACKAGES_ARR[@]} -gt 0 ] && ([ "$ASSUME_YES" = true ] || [ "$INTERACTIVE" = false ])); then
  # Proceed if PACKAGES_TO_PROCESS is set, or if it's empty but we default to all available
  if [ "$VERBOSE" = "1" ]; then
    echo -e "${PURPLE}DEBUG: Calling manage_dotfiles with 'link'${NC}"
  fi
  manage_dotfiles "link"
  manage_ec=$?
  if [ "$VERBOSE" = "1" ]; then
    echo -e "${PURPLE}DEBUG: manage_dotfiles returned with status $manage_ec${NC}"
  fi
else
  if [ "$QUIET" = false ]; then
    print_message "$YELLOW" "No packages selected or available to process."
  fi
fi

# =============================================================================
# Completion Summary
# =============================================================================

if [ "$QUIET" = false ]; then
  print_header "Setup Complete"
  if [ $manage_ec -eq 0 ]; then
    print_message "$GREEN" "Dotfiles processing finished successfully!"
  else
    print_message "$RED" "Dotfiles processing finished with errors."
  fi

  # Print installation summary
  print_installation_summary

  echo
  print_message "$YELLOW" "Enjoy your environment!"
fi

# Disable error trap before exiting
trap - ERR

exit $manage_ec
