#!/usr/bin/env bash
# Improved macOS install script

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to print status messages
print_status() {
  echo "📦 $1..."
}

# Function to install Homebrew package
brew_install() {
  if ! brew list "$1" &>/dev/null; then
    print_status "Installing $1"
    brew install "$1"
  else
    echo "$1 is already installed"
  fi
}

# Check if Homebrew is installed
if ! command_exists brew; then
  print_status "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ $(uname -m) == 'arm64' ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>$HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# Update Homebrew and upgrade any existing formulae
print_status "Updating Homebrew"
brew update
brew upgrade

# Check if ZSH_CUSTOM is set
if [ -z "$ZSH_CUSTOM" ]; then
  echo "Error: ZSH_CUSTOM is not set. Please ensure Oh My Zsh is installed."
  exit 1
fi

# Install Powerlevel10k theme
print_status "Installing Powerlevel10k theme"
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k
else
  echo "Powerlevel10k theme already installed"
fi

# Install Neovim and dependencies
print_status "Installing Neovim and dependencies"
brew_install "neovim"
brew_install "ripgrep" # for telescope file finding
brew_install "fd"      # for telescope file finding
brew_install "gnu-sed" # for better sed compatibility

# Install Node Version Manager
print_status "Installing Node Version Manager"
if [ ! -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

  # Load nvm and install latest LTS version
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  print_status "Installing Node.js LTS version"
  nvm install --lts
  nvm use --lts
else
  echo "NVM already installed"
fi

# Install Tmux
print_status "Installing Tmux"
brew_install "tmux"

# Install Tmux Plugin Manager if not already installed
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  print_status "Installing Tmux Plugin Manager"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "Please install your plugins (prefix + I)"
fi

# Install Lazygit
print_status "Installing Lazygit"
brew_install "lazygit"

# Install additional useful tools
print_status "Installing additional tools"
brew_install "fzf" # Fuzzy finder
brew_install "bat" # Better cat
brew_install "exa" # Better ls
brew_install "jq"  # JSON processor
brew_install "gh"  # GitHub CLI

# Install Fonts (optional but recommended for Powerlevel10k)
print_status "Installing recommended fonts"
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# Final setup and cleanup
print_status "Running final cleanup"
brew cleanup

echo "Installation complete! Please restart your terminal."
echo "Additional notes:"
echo "1. Run 'p10k configure' to set up Powerlevel10k"
echo "2. Install Tmux plugins with prefix + I (usually ctrl + b then shift + i)"
echo "3. The following tools were also installed:"
echo "   - ripgrep (rg) for faster searching"
echo "   - fd for better file finding"
echo "   - fzf for fuzzy finding"
echo "   - bat for better file viewing"
echo "   - exa for better directory listing"
echo "   - jq for JSON processing"
echo "   - gh for GitHub CLI"
