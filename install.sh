#!/usr/bin/env bash

currentDir=$(pwd)
OS="echo $(uname)"
zshell="$(which zsh)"



# Check OS then run installation script
echo "Checking OS"

if [[ "$OS" = *"Linux"* ]]; then
    rm ~/.zshrc

    # Install stow

    echo "Installing stow"
    sudo apt-get update -y
    sudo apt-get install stow -y

    # Run link files
    
    echo "Linking dotfiles..."
    $currentDir/installs/link_files.sh

    # Running Install script for Ubuntu
    $currentDir/installs/install_linux.sh
    



    # Changing shell to zshell
    # echo "Changing default shell, please enter password"
    # chsh -s "$(which zsh)"

    echo "Installation Complete. Double check if extensions, plugins and/or updates are manually installed before using apps. Restart terminal to see changes"
elif [[ "$OS" = *"Darwin"* ]]; then
    rm ~/.zshrc

    # Install stow
    echo "Installing stow"
    brew install stow

    # Run link files
    echo "Linking dotfiles..."
    $currentDir/installs/link_files.sh

    # Running Install script for macOs
    $currentDir/installs/install_mac.sh

    


    # Changing shell to zshell
    # echo "Changing default shell, please enter password"
    # chsh -s "$(which zsh)"

    echo "Installation Complete. Double check if extensions, plugins and/or updates are manually installed before using apps. Restart terminal to see changes"
else 
  echo "OS Unkown"
fi

# chsh -s "$(which zsh)"

