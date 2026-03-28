#!/bin/bash
#
# CLI Argument Parsing Module for install.sh
# Handles command-line flag parsing and global variable initialization
#

# =============================================================================
# Global Variable Declarations
# =============================================================================

# Base directory for dotfiles (default: script location)
DOTFILES_DIR="${SCRIPT_DIR:-}"

# Operation mode flags
UNLINK=false
ASSUME_YES=false
INTERACTIVE=false
QUIET=false
LINK_ONLY=false
INSTALL_NVM=false
VERBOSE="${VERBOSE:-0}"
# Package selection
PACKAGES_TO_PROCESS=""

# =============================================================================
# TTY Detection
# =============================================================================

# Auto-enable interactive mode if both stdin and stdout are TTYs
if [ -t 0 ] && [ -t 1 ]; then
  INTERACTIVE=true
fi

# =============================================================================
# Argument Parsing
# =============================================================================

# Parse command line arguments
# Usage: parse_arguments "$@"
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    local key="$1"
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
        PACKAGES_TO_PROCESS="$2"
        shift
        shift
        ;;
      --install-nvm)
        INSTALL_NVM=true
        shift
        ;;
      *)
        print_message "$RED" "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

# =============================================================================
# Post-Parsing Validation
# =============================================================================

# Validate and normalize DOTFILES_DIR after argument parsing
# Sets LINK_SRC_BASE_DIR as a side effect
validate_dotfiles_dir() {
  # Normalize DOTFILES_DIR to absolute path if it exists
  if [ -d "$DOTFILES_DIR" ]; then
    DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"
  else
    print_message "$RED" "Error: Dotfiles directory not found at '$DOTFILES_DIR'"
    exit 1
  fi

  # Set source base directory for package operations
  LINK_SRC_BASE_DIR="$DOTFILES_DIR"

  # Verify source directory exists
  if [ ! -d "$LINK_SRC_BASE_DIR" ]; then
    print_message "$RED" "Error: Source base directory for packages not found at: $LINK_SRC_BASE_DIR"
    exit 1
  fi
}
