#!/usr/bin/env bash
#
# distro/arch.sh
# Arch Linux installation logic for dotfiles
#
# This module contains Arch-specific dependency installation functions.
# It is sourced by the main distro/install.sh dispatcher.
#
# Dependencies:
#   - lib/logging.sh (for print_message, print_header, color codes)
#   - lib/utils.sh (for command_exists)
#   - Global state: QUIET, ASSUME_YES (defined by caller)
#   - installer functions from installers/*.sh
#
# API Contract:
#   - install_arch_dependencies() is the main entry point
#   - Uses global QUIET for silent operation
#   - Uses global ASSUME_YES for non-interactive mode
#   - Calls installer functions from installers/ directory

# -----------------------------------------------------------------------------
# Install Arch Linux dependencies
# -----------------------------------------------------------------------------
install_arch_dependencies() {
  print_header "Dependency Check for Arch Linux"
  local all_ok=true
  local arch_needed_pkgs=("gcc" "zsh" "curl" "git" "unzip" "xdg-utils") pkgs_to_install_pacman=()
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

  _install_lazyvim_prereqs_arch

  _install_starship_via_curl_script
  _install_ohmyzsh_script
  _set_zsh_default_shell
  _install_bun_script
  _install_opencode_script
  _install_claude_code_script
  _install_factory_cli_script
  _install_nvm
  _install_catppuccin_tmux

  _install_ghostty_arch
  _install_eza_arch
  _install_playwright_cli_script

  if ! $all_ok; then return 1; fi
  return 0
}

# -----------------------------------------------------------------------------
# Install Ghostty terminal emulator (Arch-specific via pacman)
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Install eza (modern ls replacement) (Arch-specific via pacman)
# -----------------------------------------------------------------------------
_install_eza_arch() {
  # eza installation via pacman (Arch Linux)
  if command_exists eza; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  eza is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install eza (modern ls replacement) using pacman?" "y"; then
    local pacman_cmd="sudo pacman -S --needed --noconfirm eza"
    if [ "$ASSUME_YES" = false ]; then pacman_cmd="sudo pacman -S --needed eza"; fi
    echo -n -e "${CYAN}    pacman -S eza... ${NC}"
    if eval "$pacman_cmd" >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    eza installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    eza installation failed."
    fi
  else print_message "$YELLOW" "  eza installation skipped."; fi
}
