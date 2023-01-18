#!/usr/bin/env bash

# ZSH INSTALLS
echo "Installing zsh"

brew install zsh

echo "Installing oh-my-zsh"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# powerlevel10k theme for omz
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Change Shell
chsh -s $(which zsh)

# NEOVIM INSTALLS
echo "Installing neovim"
brew install neovim
brew install clang # To compile ya treesitter thangs

echo "Installing nvim packer and plugins"

git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

echo "NOTE: Please install your LSPs. I'm too lazy to add all the commands"

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
