#!/usr/bin/env bash

# powerlevel10k theme for omz
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# NEOVIM INSTALLS
echo "Installing neovim"
brew install neovim
#brew install clang # To compile ya treesitter thangs

# NODE VERSION MANAGER INSTALLS
# NVM directory already setup in .zshrc
echo "Installing Node Version Manager"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

#TMUX Installation
echo "Installing tmux"

brew install tmux

echo "Please install your plugins (ctrl + b + shift + i)"

# lazygit Installation

echo "Installing lazygit"

brew install lazygit
