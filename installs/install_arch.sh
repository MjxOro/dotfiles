#!/usr/bin/env bash
# Arch Linux install script

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to print status messages
print_status() {
  echo "📦 $1..."
}

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ] && ! sudo -v; then
  echo "Error: This script requires sudo privileges"
  exit 1
fi

# Check if ZSH_CUSTOM is set
if [ -z "$ZSH_CUSTOM" ]; then
  echo "Error: ZSH_CUSTOM is not set. Please ensure Oh My Zsh is installed."
  exit 1
fi

# Ensure system is up to date
print_status "Updating system"
sudo pacman -Syu --noconfirm

print_status "Installing Powerlevel10k theme"
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k
else
  echo "Powerlevel10k theme already installed"
fi

# Install Neovim
print_status "Installing Neovim"
if ! command_exists nvim; then
  sudo pacman -S neovim --noconfirm
else
  echo "Neovim already installed"
fi

# Install NVM
print_status "Installing Node Version Manager"
if [ ! -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Load nvm
  # Install latest LTS version of Node
  nvm install --lts
else
  echo "NVM already installed"
fi

# Install Tmux
print_status "Installing Tmux"
if ! command_exists tmux; then
  sudo pacman -S tmux --noconfirm
  echo "Please install your plugins (ctrl + b + shift + i)"
else
  echo "Tmux already installed"
fi

# Install Lazygit
print_status "Installing Lazygit"
if ! command_exists lazygit; then
  # Check if yay is installed (for AUR access)
  if command_exists yay; then
    yay -S lazygit --noconfirm
  else
    # Manual installation if yay is not available
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v*([^"]+)".*/\1/')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    sudo tar xf lazygit.tar.gz -C /usr/local/bin lazygit
    rm lazygit.tar.gz
  fi
else
  echo "Lazygit already installed"
fi

echo "Installation complete! Please restart your terminal."
