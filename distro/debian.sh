#!/bin/bash
# ============================================================================
# Debian/Ubuntu Installation Module
# ============================================================================
# Provides Debian/Ubuntu-specific installation logic for dotfiles dependencies.
# This module orchestrates calls to installers/* functions for cross-platform tools.
# ============================================================================

# Dependencies: lib/logging.sh, lib/utils.sh (must be sourced by caller)
# Also depends on installers/* functions being available

# ----------------------------------------------------------------------------
# Tree-sitter CLI Helpers
# ----------------------------------------------------------------------------

_tree_sitter_cli_usable() {
  command_exists tree-sitter && tree-sitter --version >/dev/null 2>&1
}

_install_tree_sitter_cli_cargo_debian() {
  if _tree_sitter_cli_usable; then
    return 0
  fi

  if ! command_exists cargo; then
    if ask_yes_no "  Install cargo/rustc to build tree-sitter CLI from source?" "y"; then
      echo -n -e "${CYAN}  Installing cargo and rustc... ${NC}"
      if sudo apt-get install -y cargo rustc >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${YELLOW}!${NC}"
        print_message "$YELLOW" "  Could not install cargo/rustc via apt."
        return 0
      fi
    else
      print_message "$YELLOW" "  cargo/rustc installation skipped; cannot build tree-sitter CLI from source."
      return 0
    fi
  fi

  if ! command_exists cargo; then
    print_message "$YELLOW" "  cargo is not available on PATH; skipping source build fallback."
    return 0
  fi

  if ask_yes_no "  Build and install tree-sitter CLI with cargo (recommended fallback)?" "y"; then
    echo -n -e "${CYAN}  Building tree-sitter CLI with cargo (this may take a while)... ${NC}"
    if cargo install --locked tree-sitter-cli >/dev/null 2>&1 || cargo install tree-sitter-cli >/dev/null 2>&1; then
      export PATH="$HOME/.cargo/bin:$PATH"
      if _tree_sitter_cli_usable; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${YELLOW}!${NC}"
        print_message "$YELLOW" "  cargo install completed, but 'tree-sitter --version' still failed."
      fi
    else
      echo -e "${YELLOW}!${NC}"
      print_message "$YELLOW" "  cargo install tree-sitter-cli failed."
    fi
  else
    print_message "$YELLOW" "  cargo fallback for tree-sitter CLI skipped."
  fi
}

# ----------------------------------------------------------------------------
# LazyGit Installation (Debian/Ubuntu)
# ----------------------------------------------------------------------------

_install_lazygit_debian() {
  if command_exists lazygit; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  LazyGit is already installed."; fi
    return 0
  fi

  if ! ask_yes_no "  Install LazyGit (required by LazyVim extras) on Debian/Ubuntu?" "y"; then
    print_message "$YELLOW" "  LazyGit installation skipped."
    return 0
  fi

  # First try: native repositories (works on newer Debian/Ubuntu)
  local candidate=""
  if command_exists apt-cache; then
    candidate=$(apt-cache policy lazygit 2>/dev/null | awk '/Candidate:/{print $2; exit}')
  fi
  if [ -n "$candidate" ] && [ "$candidate" != "(none)" ]; then
    echo -n -e "${CYAN}  Installing lazygit with apt... ${NC}"
    if sudo apt-get install -y lazygit >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      return 0
    fi
    echo -e "${YELLOW}!${NC}"
    print_message "$YELLOW" "  apt install lazygit failed; will try GitHub release binary."
  fi

  # Fallback: GitHub release binary (reliable on Ubuntu LTS where apt lacks lazygit)
  if ! command_exists curl; then
    print_message "$YELLOW" "  curl not found; cannot install LazyGit from GitHub releases."
    return 0
  fi
  if ! command_exists tar; then
    print_message "$YELLOW" "  tar not found; cannot install LazyGit from GitHub releases."
    return 0
  fi

  local arch_suffix=""
  case "$(uname -m)" in
    x86_64 | amd64) arch_suffix="x86_64" ;;
    aarch64 | arm64) arch_suffix="arm64" ;;
    armv6l | armv7l) arch_suffix="armv6" ;;
    *)
      print_message "$YELLOW" "  Unsupported CPU architecture for LazyGit binary: $(uname -m)"
      return 0
      ;;
  esac

  local latest_url="" latest_tag="" version="" asset="" download_url="" tmp_dir=""
  latest_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/jesseduffield/lazygit/releases/latest 2>/dev/null || true)
  latest_tag=${latest_url##*/}

  if [[ -z "$latest_tag" || "$latest_tag" != v* ]]; then
    print_message "$YELLOW" "  Failed to determine latest LazyGit release tag from GitHub."
    return 0
  fi
  version="${latest_tag#v}"
  asset="lazygit_${version}_Linux_${arch_suffix}.tar.gz"
  download_url="https://github.com/jesseduffield/lazygit/releases/download/${latest_tag}/${asset}"

  tmp_dir=$(mktemp -d 2>/dev/null || true)
  if [ -z "$tmp_dir" ] || [ ! -d "$tmp_dir" ]; then
    print_message "$YELLOW" "  Failed to create temp directory for LazyGit download."
    return 0
  fi

  echo -n -e "${CYAN}  Downloading LazyGit ${latest_tag} (${arch_suffix})... ${NC}"
  if curl -fsSL "$download_url" -o "$tmp_dir/$asset" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${YELLOW}!${NC}"
    print_message "$YELLOW" "  Failed to download LazyGit from: $download_url"
    rm -rf "$tmp_dir" >/dev/null 2>&1 || true
    return 0
  fi

  echo -n -e "${CYAN}  Installing LazyGit to $HOME/.local/bin/lazygit... ${NC}"
  if tar -xzf "$tmp_dir/$asset" -C "$tmp_dir" >/dev/null 2>&1 && [ -f "$tmp_dir/lazygit" ]; then
    mkdir -p "$HOME/.local/bin"
    if command_exists install; then
      if install -m 0755 "$tmp_dir/lazygit" "$HOME/.local/bin/lazygit" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${YELLOW}!${NC}"
        print_message "$YELLOW" "  Failed to install lazygit binary to $HOME/.local/bin."
      fi
    else
      if cp "$tmp_dir/lazygit" "$HOME/.local/bin/lazygit" >/dev/null 2>&1 && chmod +x "$HOME/.local/bin/lazygit" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${YELLOW}!${NC}"
        print_message "$YELLOW" "  Failed to copy lazygit binary to $HOME/.local/bin."
      fi
    fi
  else
    echo -e "${YELLOW}!${NC}"
    print_message "$YELLOW" "  Failed to extract LazyGit tarball."
  fi

  rm -rf "$tmp_dir" >/dev/null 2>&1 || true
  return 0
}

# ----------------------------------------------------------------------------
# LazyVim Prerequisites (Debian/Ubuntu)
# ----------------------------------------------------------------------------

_install_lazyvim_prereqs_debian() {
  # LazyVim prereqs based on https://lazyvim.github.io/installation (docker example)
  # - neovim (handled separately in install_debian_dependencies), git, curl, ripgrep, fd-find, lazygit, tree-sitter-cli
  local pkgs_to_install=()

  if ! dpkg-query -W -f='${Status}' ripgrep 2>/dev/null | grep -q "ok installed" && ! command_exists rg; then
    pkgs_to_install+=("ripgrep")
  fi
  if ! dpkg-query -W -f='${Status}' fd-find 2>/dev/null | grep -q "ok installed" && ! command_exists fdfind; then
    pkgs_to_install+=("fd-find")
  fi

  if [ ${#pkgs_to_install[@]} -gt 0 ]; then
    if ask_yes_no "  Install LazyVim prerequisites with apt (${pkgs_to_install[*]})?" "y"; then
      echo -n -e "${CYAN}  Installing with apt: ${pkgs_to_install[*]}... ${NC}"
      if sudo apt-get install -y "${pkgs_to_install[@]}" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${YELLOW}!${NC}"
        print_message "$YELLOW" "  Could not install some LazyVim prerequisites via apt: ${pkgs_to_install[*]}."
      fi
    fi
  fi

  _install_lazygit_debian

  if ! _tree_sitter_cli_usable; then
    if ask_yes_no "  Install tree-sitter CLI (LazyVim prerequisite) with apt?" "y"; then
      echo -n -e "${CYAN}  Installing tree-sitter CLI... ${NC}"
      if sudo apt-get install -y tree-sitter-cli >/dev/null 2>&1 || sudo apt-get install -y tree-sitter >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
      else
        echo -e "${YELLOW}!${NC}"
        print_message "$YELLOW" "  Could not install tree-sitter CLI via apt (tree-sitter-cli/tree-sitter)."
      fi
    fi
  fi

  if ! _tree_sitter_cli_usable; then
    _install_tree_sitter_cli_cargo_debian
  fi

  # Debian/Ubuntu fd package provides `fdfind`. Many tools expect `fd`.
  if ! command_exists fd && command_exists fdfind; then
    if ask_yes_no "  Create 'fd' symlink to 'fdfind' for LazyVim?" "y"; then
      mkdir -p "$HOME/.local/bin"
      ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
      if [ "$QUIET" = false ]; then print_message "$GREEN" "  Created symlink: $HOME/.local/bin/fd -> $(command -v fdfind)"; fi
    fi
  fi
}

# ----------------------------------------------------------------------------
# Ghostty Installation (Info Only)
# ----------------------------------------------------------------------------

# Ghostty installation guidance for Debian/Ubuntu
# Ghostty is not in official Debian/Ubuntu repos, must be built from source or use unofficial methods
_install_ghostty_debian() {
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

# ----------------------------------------------------------------------------
# eza Installation (Debian/Ubuntu)
# ----------------------------------------------------------------------------

# eza installation via apt with GPG key (Debian/Ubuntu)
_install_eza_debian() {
  if command_exists eza; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  eza is already installed."; fi
    return 0
  fi
  if ask_yes_no "  Install eza (modern ls replacement) from gierens.de repository?" "y"; then
    echo -n -e "${CYAN}    Setting up eza repository... ${NC}"
    local eza_install_ok=true
    
    # Ensure gpg is installed
    if ! command_exists gpg; then
      if ! sudo apt-get install -y gpg >/dev/null 2>&1; then
        echo -e "${RED}✗${NC}"
        print_message "$RED" "    Failed to install gpg."
        return 1
      fi
    fi
    
    # Add GPG key and repository
    if sudo mkdir -p /etc/apt/keyrings && \
       wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null && \
       echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null && \
       sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list; then
      echo -e "${GREEN}✓${NC}"
    else
      echo -e "${RED}✗${NC}"
      print_message "$RED" "    Failed to set up eza repository."
      eza_install_ok=false
    fi
    
    if [ "$eza_install_ok" = true ]; then
      echo -n -e "${CYAN}    apt update && apt install eza... ${NC}"
      if sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y eza >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        if [ "$QUIET" = false ]; then print_message "$GREEN" "    eza installed successfully."; fi
      else
        echo -e "${RED}✗${NC}"
        print_message "$RED" "    eza installation failed."
      fi
    fi
  else print_message "$YELLOW" "  eza installation skipped."; fi
}

# ----------------------------------------------------------------------------
# Main Debian/Ubuntu Dependency Installation
# ----------------------------------------------------------------------------

install_debian_dependencies() {
  print_header "Installing Dependencies for Debian/Ubuntu"
  local all_ok=true

  if [ "$QUIET" = false ]; then print_message "$BLUE" "Updating package lists (sudo)..."; fi
  echo -n -e "${CYAN}Updating apt package lists... ${NC}"
  if sudo apt-get update -y >/dev/null 2>&1; then echo -e "${GREEN}✓${NC}"; else
    echo -e "${RED}✗${NC}"; print_message "$RED" "Failed to update apt lists."; all_ok=false
  fi

  local essential_deps_script=("git" "curl" "software-properties-common" "build-essential" "zsh" "unzip" "xdg-utils")
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

  # Neovim installation via unstable PPA
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

  # Orchestrate calls to installers/* functions
  _install_lazyvim_prereqs_debian

  _install_starship_via_curl_script
  _install_ohmyzsh_script
  _set_zsh_default_shell
  _install_bun_script
  _install_opencode_script
  _install_claude_code_script
  _install_factory_cli_script
  _install_nvm
  _install_catppuccin_tmux

  _install_ghostty_debian
  _install_eza_debian
  _install_playwright_cli_script

  if ! $all_ok; then return 1; fi
  print_message "$GREEN" "Debian/Ubuntu dependency check complete."
  return 0
}
