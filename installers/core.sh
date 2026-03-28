#!/usr/bin/env bash
# Core tool installers
# Sourced by distro/* installers

dotfiles_installers_core_sh_sourced=true

# Starship prompt installer via official curl script
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

# Oh My Zsh installer
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

# Set Zsh as default shell
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

# Bun JavaScript runtime installer
_install_bun_script() {
  ensure_bun_bin_on_path
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
    ensure_bun_bin_on_path
    if [ $bun_ec -eq 0 ] && command_exists bun; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Bun installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Bun installation failed (code: $bun_ec)."
      if [ -n "$bun_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $bun_out"; fi
    fi
  else print_message "$YELLOW" "  Bun installation skipped."; fi
}

# OpenCode AI coding assistant installer
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
    if [ -f "$HOME/.opencode/bin/opencode" ]; then
      export PATH="$HOME/.opencode/bin:$PATH"
    fi
    if [ $opencode_ec -eq 0 ] && (command_exists opencode || [ -f "$HOME/.opencode/bin/opencode" ]); then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    OpenCode installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    OpenCode installation failed (code: $opencode_ec)."
      if [ -n "$opencode_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $opencode_out"; fi
    fi
  else print_message "$YELLOW" "  OpenCode installation skipped."; fi
}

# Claude Code Anthropic CLI installer
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
    if [ -f "$HOME/.claude/local/claude" ]; then
      export PATH="$HOME/.claude/local:$PATH"
    fi
    if [ $claude_ec -eq 0 ] && (command_exists claude || [ -f "$HOME/.claude/local/claude" ]); then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Claude Code installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Claude Code installation failed (code: $claude_ec)."
      if [ -n "$claude_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $claude_out"; fi
    fi
  else print_message "$YELLOW" "  Claude Code installation skipped."; fi
}

# Factory CLI (droid) installer
_install_factory_cli_script() {
  if command_exists droid && droid --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Factory CLI is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Factory CLI (droid)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for Factory CLI installation. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing Factory CLI (curl ... | sh)... ${NC}"
    local factory_out factory_ec
    if [ "$QUIET" = true ]; then
      factory_out=$(curl -fsSL https://app.factory.ai/cli 2>/dev/null | sh 2>&1); factory_ec=$?
    else
      echo
      curl -fsSL https://app.factory.ai/cli | sh; factory_ec=$?
    fi
    if [ -f "$HOME/.local/bin/droid" ]; then
      export PATH="$HOME/.local/bin:$PATH"
    fi
    if [ $factory_ec -eq 0 ] && (command_exists droid || [ -f "$HOME/.local/bin/droid" ]); then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Factory CLI installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    Factory CLI installation failed (code: $factory_ec)."
      if [ -n "$factory_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $factory_out"; fi
      return 1
    fi
  else print_message "$YELLOW" "  Factory CLI installation skipped."; fi
}

# Node Version Manager (nvm) installer
_install_nvm() {
  # Optional nvm installation, disabled by default for Bun-first setups
  if [ "${INSTALL_NVM:-false}" != "true" ]; then
    if [ "$QUIET" = false ]; then
      print_message "$YELLOW" "  nvm installation disabled by default. Use --install-nvm to enable."
    fi
    return 0
  fi

  # Node Version Manager (nvm) installation
  # zshrc already has nvm loader, so we use PROFILE=/dev/null to prevent shell config modification
  if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  nvm is already installed."; fi
    return 0
  fi
  if ! command_exists curl; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  curl not found, skipping nvm installation."; fi
    return 1
  fi
  if ask_yes_no "  Install nvm (Node Version Manager)?" "y"; then
    echo -n -e "${CYAN}    Installing nvm... ${NC}"
    local nvm_out nvm_ec
    if [ "$QUIET" = true ]; then
      nvm_out=$(PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh 2>/dev/null | bash 2>&1); nvm_ec=$?
    else
      echo
      PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash; nvm_ec=$?
    fi
    # Source nvm for immediate use in this session
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
      export NVM_DIR="$HOME/.nvm"
      \. "$NVM_DIR/nvm.sh"
    fi
    if [ $nvm_ec -eq 0 ] && [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    nvm installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    nvm installation failed (code: $nvm_ec)."
      if [ -n "$nvm_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $nvm_out"; fi
    fi
  else print_message "$YELLOW" "  nvm installation skipped."; fi
}
