#!/usr/bin/env bash
#
# lib/summary.sh
# Installation summary display module
#
# Provides print_installation_summary() function to display
# a summary of installed tools and linked configurations.
#
# Dependencies: lib/logging.sh, lib/utils.sh
#

# Source dependencies
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/utils.sh"

# ------------------------------------------------------------------------------
# Installation Summary
# ------------------------------------------------------------------------------

print_installation_summary() {
  if [ "${QUIET:-false}" = false ]; then
    print_header "Installation Summary"

    # Check installed tools
    local installed_tools=()
    local failed_tools=()

    ensure_bun_bin_on_path

    command_exists starship && installed_tools+=("Starship") || failed_tools+=("Starship")
    (command_exists bun || [ -f "$HOME/.bun/bin/bun" ]) && installed_tools+=("Bun") || failed_tools+=("Bun")
    command_exists opencode && installed_tools+=("OpenCode") || failed_tools+=("OpenCode")
    command_exists claude && installed_tools+=("Claude Code") || failed_tools+=("Claude Code")
    command_exists droid && installed_tools+=("Factory CLI") || failed_tools+=("Factory CLI")
    [ -d "$HOME/.oh-my-zsh" ] && installed_tools+=("Oh My Zsh") || failed_tools+=("Oh My Zsh")
    command_exists ghostty && installed_tools+=("Ghostty") || failed_tools+=("Ghostty")
    command_exists eza && installed_tools+=("eza") || failed_tools+=("eza")
    command_exists lazygit && installed_tools+=("LazyGit") || failed_tools+=("LazyGit")
    bun_global_command_exists playwright && installed_tools+=("Playwright") || failed_tools+=("Playwright")

     # Check linked configs
     local linked_configs=()
     [ -L "$HOME/.config/nvim" ] && linked_configs+=("Neovim")
     [ -L "$HOME/.config/starship" ] && linked_configs+=("Starship")
     [ -L "$HOME/.tmux.conf" ] && linked_configs+=("Tmux")
     [ -L "$HOME/.zshrc" ] && linked_configs+=("Zsh")
     [ -L "$HOME/.config/opencode" ] && linked_configs+=("OpenCode")
     [ -L "$HOME/.factory" ] && linked_configs+=("Factory")
      [ -L "$HOME/.config/ghostty" ] && linked_configs+=("Ghostty")
  [ -L "$HOME/.config/lazygit" ] && linked_configs+=("LazyGit")
  [ -L "$HOME/.omp" ] && linked_configs+=("OMP")
  [ -L "$HOME/.cliproxy" ] && linked_configs+=("CLIProxy")
  [ -L "$HOME/.claude" ] && linked_configs+=("Claude")
     [[ "$(uname -s)" == "Darwin" ]] && [ -L "$HOME/.config/aerospace" ] && linked_configs+=("Aerospace")
     [[ "$(uname -s)" == "Darwin" ]] && [ -L "$HOME/.config/sketchybar" ] && linked_configs+=("SketchyBar")
     [[ "$(uname -s)" == "Darwin" ]] && [ -L "$HOME/.config/borders" ] && linked_configs+=("Borders")

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
