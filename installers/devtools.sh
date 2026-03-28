#!/usr/bin/env bash
#
# installers/devtools.sh
# Development tool installers for the dotfiles setup
#
# Dependencies:
#   - lib/logging.sh (provides: print_message, color variables)
#   - lib/utils.sh (provides: command_exists, bun_global_command_exists, ensure_bun_bin_on_path)
#   - installers/core.sh (provides: _install_bun_script - called by _install_playwright_cli_script)
#
# Note: This file is meant to be sourced, not executed directly.

# shellcheck source=../lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"

# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"


# ------------------------------------------------------------------------------
# Catppuccin tmux Plugin Installer
# ------------------------------------------------------------------------------

_install_catppuccin_tmux() {
  local plugin_dir="$HOME/.config/tmux/plugins/catppuccin/tmux"
  if [ -d "$plugin_dir" ]; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Catppuccin tmux plugin is already installed."; fi
    return 0
  fi
  if ! command_exists git; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Git not found, skipping Catppuccin tmux plugin install."; fi
    return 1
  fi
  if ask_yes_no "  Install Catppuccin tmux theme plugin?" "y"; then
    echo -n -e "${CYAN}    Installing Catppuccin tmux plugin... ${NC}"
    if mkdir -p "$HOME/.config/tmux/plugins/catppuccin" && \
       git clone -b v2.1.3 https://github.com/catppuccin/tmux.git "$plugin_dir" >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Catppuccin tmux plugin installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    Catppuccin tmux plugin installation failed."
      return 1
    fi
  else
    print_message "$YELLOW" "  Catppuccin tmux plugin installation skipped."
  fi
}

# ------------------------------------------------------------------------------
# Playwright CLI Installer
# ------------------------------------------------------------------------------
# Note: This function depends on bun being installed first.
# It uses bun_global_command_exists and ensure_bun_bin_on_path from lib/utils.sh

_install_playwright_cli_script() {
  # Playwright CLI for browser automation and web development tools - BUN-FIRST IMPLEMENTATION
  if bun_global_command_exists playwright && playwright --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Playwright CLI is already installed."; fi
    return 0
  fi

  if ask_yes_no "  Install Playwright CLI (browser automation for web development)?" "y"; then
    ensure_bun_bin_on_path

    if ! command_exists bun; then
      print_message "$YELLOW" "    Bun not found. Installing Bun first..."
      if ! _install_bun_script; then
        if [ "$QUIET" = false ]; then print_message "$YELLOW" "    Bun installation step reported an error."; fi
      fi
      ensure_bun_bin_on_path
    fi

    if ! command_exists bun; then
      print_message "$RED" "    Bun is required for Playwright CLI installation."
      return 1
    fi

    if ! command_exists bunx; then
      print_message "$RED" "    bunx is required for Playwright browser installation."
      return 1
    fi

    echo -n -e "${CYAN}    Installing Playwright CLI via Bun... ${NC}"
    local pw_out pw_ec
    if [ "$QUIET" = true ]; then
      pw_out=$(bun install -g playwright 2>&1); pw_ec=$?
    else
      echo
      bun install -g playwright; pw_ec=$?
    fi

    ensure_bun_bin_on_path

    if [ $pw_ec -eq 0 ] && bun_global_command_exists playwright; then
      echo -e "${GREEN}✓${NC}"
      print_message "$GREEN" "    Playwright CLI installed successfully."
      print_message "$CYAN" "    Installing Playwright browsers (this may take a while)..."

      local pw_browser_ec=1
      if command_exists sudo && [ "$(uname -s)" = "Linux" ]; then
        if sudo env "PATH=$PATH" bunx playwright install --with-deps >/dev/null 2>&1; then
          pw_browser_ec=0
        fi
      else
        if bunx playwright install --with-deps >/dev/null 2>&1; then
          pw_browser_ec=0
        fi
      fi

      if [ $pw_browser_ec -eq 0 ]; then
        print_message "$GREEN" "    Playwright browsers installed."
      else
        print_message "$YELLOW" "    Playwright browsers installation may have failed. Run 'bunx playwright install --with-deps' manually."
      fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    Playwright CLI installation failed (code: $pw_ec)."
      if [ -n "$pw_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $pw_out"; fi
      return 1
    fi
  else
    print_message "$YELLOW" "  Playwright CLI installation skipped."
  fi
}
