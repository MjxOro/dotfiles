#!/usr/bin/env bash
#
# installers/lazyvim.sh
# LazyVim prerequisite installer functions
#
# Dependencies:
#   - lib/logging.sh (for print_message, color variables)
#   - lib/utils.sh (for command_exists, ask_yes_no)
#
# These functions install prerequisites required by LazyVim:
#   - neovim, git, curl, ripgrep, fd, lazygit, tree-sitter
#
# OS-specific variants:
#   - _install_lazyvim_prereqs_brew()    - macOS via Homebrew
#   - _install_lazyvim_prereqs_arch()    - Arch Linux via pacman
#   - _install_lazyvim_prereqs_debian()  - Debian/Ubuntu via apt
#

# Note: Source this file after sourcing lib/logging.sh and lib/utils.sh
# ------------------------------------------------------------------------------

# ==============================================================================
# macOS (Homebrew) - LazyVim Prerequisites
# ==============================================================================

_install_lazyvim_prereqs_brew() {
  # LazyVim prereqs based on https://lazyvim.github.io/installation (docker example)
  # - neovim, git, curl, ripgrep, fd, lazygit, tree-sitter
  if command_exists nvim && command_exists rg && command_exists fd && command_exists lazygit && command_exists tree-sitter; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  LazyVim prerequisites are already installed."; fi
    return 0
  fi

  if ! command_exists brew; then
    if [ "$QUIET" = false ]; then
      print_message "$YELLOW" "  Homebrew not found; skipping LazyVim prerequisites install (neovim, ripgrep, fd, lazygit, tree-sitter)."
    fi
    return 1
  fi

  local brew_pkgs=() missing_label=()
  if ! command_exists nvim; then brew_pkgs+=("neovim"); missing_label+=("neovim"); fi
  if ! command_exists rg; then brew_pkgs+=("ripgrep"); missing_label+=("ripgrep"); fi
  if ! command_exists fd; then brew_pkgs+=("fd"); missing_label+=("fd"); fi
  if ! command_exists lazygit; then brew_pkgs+=("lazygit"); missing_label+=("lazygit"); fi
  if ! command_exists tree-sitter; then brew_pkgs+=("tree-sitter"); missing_label+=("tree-sitter"); fi

  if [ ${#brew_pkgs[@]} -eq 0 ]; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  LazyVim prerequisites are already installed."; fi
    return 0
  fi

  if ask_yes_no "  Install LazyVim prerequisites using Homebrew (${missing_label[*]})?" "y"; then
    echo -n -e "${CYAN}    brew install ${brew_pkgs[*]}... ${NC}"
    if brew install "${brew_pkgs[@]}" >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      return 0
    else
      echo -e "${RED}✗${NC}"
      print_message "$YELLOW" "    Failed to install some LazyVim prerequisites via brew."
      return 0
    fi
  else
    print_message "$YELLOW" "  LazyVim prerequisites installation skipped."
    return 0
  fi
}

# ==============================================================================
# Arch Linux (pacman) - LazyVim Prerequisites
# ==============================================================================

_install_lazyvim_prereqs_arch() {
  # LazyVim prereqs based on https://lazyvim.github.io/installation (docker example)
  # - neovim, git, curl, ripgrep, fd, lazygit, tree-sitter
  local pacman_pkgs=("neovim" "ripgrep" "fd" "lazygit" "tree-sitter")
  local missing_pkgs=()

  for pkg in "${pacman_pkgs[@]}"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
      missing_pkgs+=("$pkg")
    fi
  done

  if [ ${#missing_pkgs[@]} -eq 0 ]; then
    if [ "$QUIET" = false ]; then print_message "$GREEN" "  LazyVim prerequisites are already installed."; fi
    return 0
  fi

  if ask_yes_no "  Install LazyVim prerequisites using pacman (${missing_pkgs[*]})?" "y"; then
    local pacman_cmd="sudo pacman -S --needed --noconfirm ${missing_pkgs[*]}"
    if [ "$ASSUME_YES" = false ]; then pacman_cmd="sudo pacman -S --needed ${missing_pkgs[*]}"; fi
    echo -n -e "${CYAN}    pacman -S ${missing_pkgs[*]}... ${NC}"
    if eval "$pacman_cmd" >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
      return 0
    else
      echo -e "${RED}✗${NC}"
      print_message "$YELLOW" "    Failed to install some LazyVim prerequisites via pacman."
      return 0
    fi
  else
    print_message "$YELLOW" "  LazyVim prerequisites installation skipped."
    return 0
  fi
}

# ==============================================================================
# Debian/Ubuntu (apt) - LazyVim Prerequisites
# ==============================================================================

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
