#!/usr/bin/env bash
currentDir=$(pwd)
OS=$(uname)
zshell=$(which zsh)

# Function to change shell to zsh if not already zsh
change_shell_to_zsh() {
  if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Current shell is not zsh. Changing default shell to zsh..."
    if [ -n "$zshell" ]; then
      chsh -s "$zshell"
    else
      echo "Warning: zsh not found. Please install zsh first"
      exit 1
    fi
  else
    echo "Shell is already zsh"
  fi
}

# Check OS then run installation script
echo "Checking OS"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" == "debian" ]] || [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID" == "ubuntu" ]]; then
    echo "Debian/Ubuntu based system detected"
    [ -f ~/.zshrc ] && rm ~/.zshrc

    # Install zsh if not present
    if ! command -v zsh >/dev/null 2>&1; then
      echo "Installing zsh"
      sudo apt-get update -y
      sudo apt-get install zsh -y
    fi

    # Install stow
    echo "Installing stow"
    sudo apt-get update -y
    sudo apt-get install stow -y

    echo "Linking dotfiles..."
    if [ -f "$currentDir/installs/link_files.sh" ]; then
      $currentDir/installs/link_files.sh
    else
      echo "Error: link_files.sh not found"
      exit 1
    fi

    if [ -f "$currentDir/installs/install_deb.sh" ]; then
      $currentDir/installs/install_deb.sh
    else
      echo "Error: install_deb.sh not found"
      exit 1
    fi

    # Change shell to zsh
    change_shell_to_zsh

  elif [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" == *"arch"* ]]; then
    echo "Arch Linux detected"
    [ -f ~/.zshrc ] && rm ~/.zshrc

    # Install zsh if not present
    if ! command -v zsh >/dev/null 2>&1; then
      echo "Installing zsh"
      sudo pacman -S zsh --noconfirm
    fi

    # Install stow
    echo "Installing stow"
    sudo pacman -Syu --noconfirm
    sudo pacman -S stow --noconfirm

    echo "Linking dotfiles..."
    if [ -f "$currentDir/installs/link_files.sh" ]; then
      $currentDir/installs/link_files.sh
    else
      echo "Error: link_files.sh not found"
      exit 1
    fi

    if [ -f "$currentDir/installs/install_arch.sh" ]; then
      $currentDir/installs/install_arch.sh
    else
      echo "Error: install_arch.sh not found"
      exit 1
    fi

    # Change shell to zsh
    change_shell_to_zsh
  fi
elif [[ "$OS" == "Darwin"* ]]; then
  echo "macOS detected"
  [ -f ~/.zshrc ] && rm ~/.zshrc

  if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew is not installed. Please install it first."
    exit 1
  fi

  # Install stow
  echo "Installing stow"
  brew install stow

  echo "Linking dotfiles..."
  if [ -f "$currentDir/installs/link_files.sh" ]; then
    $currentDir/installs/link_files.sh
  else
    echo "Error: link_files.sh not found"
    exit 1
  fi

  if [ -f "$currentDir/installs/install_mac.sh" ]; then
    $currentDir/installs/install_mac.sh
  else
    echo "Error: install_mac.sh not found"
    exit 1
  fi

  # No need to change shell on macOS as it's already zsh by default
  echo "Using default macOS zsh shell"
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

echo "Installation Complete. Double check if extensions, plugins and/or updates are manually installed before using apps. Restart terminal to see changes"
