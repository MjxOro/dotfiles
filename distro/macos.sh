#!/usr/bin/env bash
# =============================================================================
# macOS Distribution Module
# =============================================================================
# This module provides macOS-specific installation logic.
# It orchestrates all macOS installers and handles Xcode Command Line Tools.
#
# Dependencies:
#   - lib/logging.sh (print_header, print_message)
#   - lib/utils.sh (command_exists, ask_yes_no)
#   - installers/* (core/devtools/lazyvim installers)
#
# Globals Used:
#   - QUIET: If true, suppress non-essential output
#   - ASSUME_YES: If true, assume yes for prompts (non-interactive)
#   - GREEN, YELLOW, RED, CYAN, NC: Color codes
# =============================================================================

# =============================================================================
# Private Helper: Install Ghostty via Homebrew
# =============================================================================
# Installs Ghostty terminal emulator using Homebrew on macOS.
# Returns 0 on success or if already installed/skipped.
# =============================================================================
_install_ghostty_brew() {
  # Ghostty installation via Homebrew (macOS)
  if command_exists ghostty; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Ghostty is already installed."; fi
    return 0
  fi
  if ! command_exists brew; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Homebrew not found, cannot install Ghostty via brew."; fi
    return 0
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

# =============================================================================
# Private Helper: Install eza via Homebrew
# =============================================================================
# Installs eza (modern ls replacement) using Homebrew on macOS.
# Returns 0 on success or if already installed, 1 on failure.
# =============================================================================
_install_eza_brew() {
  # eza installation via Homebrew (macOS)
  if command_exists eza; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  eza is already installed."; fi
    return 0
  fi
  if ! command_exists brew; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Homebrew not found, cannot install eza via brew."; fi
    return 1
  fi
  if ask_yes_no "  Install eza (modern ls replacement) using Homebrew?" "y"; then
    echo -n -e "${CYAN}    brew install eza... ${NC}"
    if brew install eza >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    eza installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    eza installation failed."
    fi
  else print_message "$YELLOW" "  eza installation skipped."; fi
}

# =============================================================================
# Public Function: Install macOS Dependencies
# =============================================================================
# Orchestrates all macOS-specific dependency installations.
# Checks for Xcode Command Line Tools, then calls all core/devtools/lazyvim
# installers in the proper sequence.
#
# Returns:
#   0 if all installations successful or skipped
#   1 if any critical installation failed
# =============================================================================
install_mac_dependencies() {
  print_header "Dependency Check for macOS"
  local all_ok=true

  # Check for Xcode Command Line Tools (provides GCC, Git, etc.)
  if ! command_exists gcc; then
    if ask_yes_no "  Install Xcode Command Line Tools (provides GCC, Git, etc.)?" "y"; then
      if [ "$ASSUME_YES" = true ]; then
        print_message "$YELLOW" "    Xcode Tools install needs GUI. Run 'xcode-select --install' manually."
      else
        print_message "$BLUE" "  Triggering Xcode Tools install. Follow GUI prompts."
        xcode-select --install
      fi
    fi
  elif [ "$QUIET" = false ]; then
    print_message "$GREEN" "  GCC (from Xcode Tools) is installed."
  fi

  # Install LazyVim prerequisites (neovim, ripgrep, fd, lazygit, tree-sitter)
  _install_lazyvim_prereqs_brew

  # Install Starship prompt via Homebrew
  if ! command_exists starship; then
    if command_exists brew && ask_yes_no "  Install Starship (prompt) using Homebrew?" "y"; then
      echo -n -e "${CYAN}    brew install starship... ${NC}"
      if brew install starship >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${RED}✗${NC}"
      fi
    elif [ "$QUIET" = false ] && ! command_exists brew; then
      print_message "$YELLOW" "  Homebrew not found, cannot install Starship via brew."
    fi
  elif [ "$QUIET" = false ]; then
    print_message "$GREEN" "  Starship is already installed."
  fi

  # Core installers
  _install_ohmyzsh_script
  _set_zsh_default_shell
  _install_bun_script
  _install_opencode_script
  _install_claude_code_script
  _install_factory_cli_script
  _install_nvm
  _install_catppuccin_tmux

  # macOS-specific installers
  _install_ghostty_brew
  _install_eza_brew
  _install_playwright_cli_script

  if ! $all_ok; then return 1; fi
  return 0
}
