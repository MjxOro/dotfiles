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
    local s_out="" s_ec
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
    local omz_out="" omz_ec
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
    local bun_out="" bun_ec
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

# Claude Code Anthropic CLI installer
_install_claude_code_script() {
  if command_exists claude && claude --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Claude Code is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Claude Code (Anthropic's CLI)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for Claude Code installation. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing Claude Code (curl ... | bash)... ${NC}"
    local claude_out="" claude_ec
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

# Kimi Code (Moonshot AI) CLI installer
_install_kimi_code_script() {
  if [ -d "$HOME/.kimi-code/bin" ]; then
    case ":$PATH:" in
      *":$HOME/.kimi-code/bin:"*) ;;
      *) export PATH="$HOME/.kimi-code/bin:$PATH" ;;
    esac
  fi
  if command_exists kimi && kimi --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Kimi Code is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Kimi Code (Moonshot's CLI)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for Kimi Code installation. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing Kimi Code (curl ... | bash)... ${NC}"
    local kimi_out="" kimi_ec
    # KIMI_NO_MODIFY_PATH keeps upstream from appending to the symlinked .zshrc;
    # PATH is managed via dotfiles/zsh/.zshrc instead.
    if [ "$QUIET" = true ]; then
      kimi_out=$(KIMI_NO_MODIFY_PATH=1 curl -fsSL https://code.kimi.com/kimi-code/install.sh 2>/dev/null | bash 2>&1); kimi_ec=$?
    else
      echo
      KIMI_NO_MODIFY_PATH=1 curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash; kimi_ec=$?
    fi
    if [ -d "$HOME/.kimi-code/bin" ]; then
      case ":$PATH:" in
        *":$HOME/.kimi-code/bin:"*) ;;
        *) export PATH="$HOME/.kimi-code/bin:$PATH" ;;
      esac
    fi
    if [ $kimi_ec -eq 0 ] && command_exists kimi; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Kimi Code installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Kimi Code installation failed (code: $kimi_ec)."
      if [ -n "$kimi_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $kimi_out"; fi
    fi
  else print_message "$YELLOW" "  Kimi Code installation skipped."; fi
}

# Codex CLI (OpenAI) installer
_install_codex_script() {
  if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
  fi
  if command_exists codex && codex --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Codex CLI is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install Codex CLI (OpenAI's CLI)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for Codex CLI installation. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing Codex CLI (curl ... | sh)... ${NC}"
    local codex_out="" codex_ec
    if [ "$QUIET" = true ]; then
      codex_out=$(curl -fsSL https://chatgpt.com/codex/install.sh 2>/dev/null | sh 2>&1); codex_ec=$?
    else
      echo
      curl -fsSL https://chatgpt.com/codex/install.sh | sh; codex_ec=$?
    fi
    if [ $codex_ec -eq 0 ] && command_exists codex; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Codex CLI installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    Codex CLI installation failed (code: $codex_ec)."
      if [ -n "$codex_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $codex_out"; fi
    fi
  else print_message "$YELLOW" "  Codex CLI installation skipped."; fi
}

# OmO (oh-my-openagent) CLI installer
_install_omo_script() {
  if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
  fi
  if command_exists omo && omo --version >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  OmO is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install OmO (oh-my-openagent CLI)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for OmO installation. Please install curl."; return 1; fi
    echo -n -e "${CYAN}    Installing OmO (curl ... | bash)... ${NC}"
    local omo_out="" omo_ec
    # OMO_NO_MODIFY_PATH keeps upstream from appending to the symlinked .zshrc;
    # ~/.local/bin is already on PATH via dotfiles/zsh/.zshrc.
    if [ "$QUIET" = true ]; then
      omo_out=$(curl -fsSL https://get.omo.dev/install.sh 2>/dev/null | OMO_NO_MODIFY_PATH=1 bash 2>&1); omo_ec=$?
    else
      echo
      curl -fsSL https://get.omo.dev/install.sh | OMO_NO_MODIFY_PATH=1 bash; omo_ec=$?
    fi
    if [ -d "$HOME/.local/bin" ]; then
      case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
      esac
    fi
    if [ $omo_ec -eq 0 ] && command_exists omo; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    OmO installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"; print_message "$RED" "    OmO installation failed (code: $omo_ec)."
      if [ -n "$omo_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $omo_out"; fi
    fi
  else print_message "$YELLOW" "  OmO installation skipped."; fi
}

# herdr terminal workspace manager installer
_install_herdr_script() {
  if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
  fi
  if command_exists herdr; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  herdr is already installed."; fi
    if ask_yes_no "  Update herdr to the latest version?" "y"; then
      echo -n -e "${CYAN}    Updating herdr (herdr update)... ${NC}"
      local herdr_up_out="" herdr_up_ec
      if [ "$QUIET" = true ]; then
        herdr_up_out=$(herdr update 2>&1); herdr_up_ec=$?
      else
        echo
        herdr update; herdr_up_ec=$?
      fi
      if [ $herdr_up_ec -eq 0 ]; then echo -e "${GREEN}✓${NC}"; else
        echo -e "${RED}✗${NC}"; print_message "$RED" "    herdr update failed (code: $herdr_up_ec)."
        if [ -n "$herdr_up_out" ]; then print_message "$GRAY" "    Output: $herdr_up_out"; fi
      fi
    fi
    return 0
  fi
  if ask_yes_no "  Install herdr (terminal workspace manager)?" "y"; then
    if ! command_exists curl; then print_message "$RED" "    curl is required for herdr installation. Please install curl."; return 1; fi
    if ! command_exists awk; then print_message "$RED" "    awk is required for herdr installation. Please install awk."; return 1; fi
    echo -n -e "${CYAN}    Installing herdr (curl ... | sh)... ${NC}"
    local herdr_out="" herdr_ec
    if [ "$QUIET" = true ]; then
      herdr_out=$(curl -fsSL https://herdr.dev/install.sh 2>/dev/null | sh 2>&1); herdr_ec=$?
    else
      echo
      curl -fsSL https://herdr.dev/install.sh | sh; herdr_ec=$?
    fi
    if [ -d "$HOME/.local/bin" ]; then
      case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
      esac
    fi
    if [ $herdr_ec -eq 0 ] && (command_exists herdr || [ -x "$HOME/.local/bin/herdr" ]); then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    herdr installed successfully."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    herdr installation failed (code: $herdr_ec)."
      if [ -n "$herdr_out" ]; then print_message "$GRAY" "    Output: $herdr_out"; fi
      return 1
    fi
  else print_message "$YELLOW" "  herdr installation skipped."; fi
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
  if [ ! -d "$HOME/.nvm" ] || [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    if ! command_exists curl; then
      if [ "$QUIET" = false ]; then print_message "$YELLOW" "  curl not found, skipping nvm installation."; fi
      return 1
    fi
    if ask_yes_no "  Install nvm (Node Version Manager)?" "y"; then
      echo -n -e "${CYAN}    Installing nvm... ${NC}"
      local nvm_out="" nvm_ec
      if [ "$QUIET" = true ]; then
        nvm_out=$(PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh 2>/dev/null | bash 2>&1); nvm_ec=$?
      else
        echo
        PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash; nvm_ec=$?
      fi
      if [ $nvm_ec -eq 0 ] && [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
        echo -e "${GREEN}✓${NC}"
        if [ "$QUIET" = false ]; then print_message "$GREEN" "    nvm installed successfully."; fi
      else
        echo -e "${RED}✗${NC}"
        print_message "$RED" "    nvm installation failed (code: $nvm_ec)."
        if [ -n "$nvm_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $nvm_out"; fi
        return 1
      fi
    else print_message "$YELLOW" "  nvm installation skipped."; return 0; fi
  elif [ "$QUIET" = false ]; then
    print_message "$GREEN" "  nvm is already installed."
  fi

  # nvm ships no Node itself: ensure an LTS release exists and is the default
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
  else
    print_message "$RED" "    nvm.sh not found; cannot provision Node."; return 1
  fi
  local current_node; current_node=$(nvm current 2>/dev/null || echo "none")
  if [ "$current_node" != "none" ]; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  Node $current_node already active via nvm."; fi
    return 0
  fi
  if ask_yes_no "  Install LTS Node via nvm and set as default?" "y"; then
    echo -n -e "${CYAN}    Installing LTS Node (nvm install --lts)... ${NC}"
    local node_out="" node_ec
    if [ "$QUIET" = true ]; then
      node_out=$(nvm install --lts 2>&1 && nvm alias default 'lts/*' >/dev/null 2>&1); node_ec=$?
    else
      echo
      nvm install --lts; node_ec=$?
      if [ $node_ec -eq 0 ]; then nvm alias default 'lts/*' >/dev/null 2>&1; node_ec=$?; fi
    fi
    if [ $node_ec -eq 0 ] && [ "$(nvm current 2>/dev/null)" != "none" ]; then
      echo -e "${GREEN}✓${NC}"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "    Node $(nvm current) active via nvm."; fi
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    LTS Node installation failed (code: $node_ec)."
      if [ -n "$node_out" ] && [ "$QUIET" = false ]; then print_message "$GRAY" "    Output: $node_out"; fi
      return 1
    fi
  else print_message "$YELLOW" "  LTS Node installation skipped."; fi
}
