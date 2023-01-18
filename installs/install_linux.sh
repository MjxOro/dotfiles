#!/usr/bin/env bash

zshell="which zsh"

# ZSH INSTALLS
echo "Installing zsh"

sudo apt install zsh -y

echo "Installing oh-my-zsh"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# powerlevel10k theme for omz
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# If WSL use this command for opening browsers from CLI
# sudo apt install wsl-open -y
# ln -sf $(which wsl-open) /usr/local/bin/xdg-open

# Change shell to zsh
chsh -s $zshell

# NEOVIM INSTALLS
echo "Installing neovim"
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo apt-get update -y
sudo apt-get install neovim -y
sudo apt install clang -y # To compile ya treesitter thangs

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
sudo apt install tmux -y

echo "Please install your plugins (ctrl + b + shift + i)"


# Lazy Git Installation

echo "Installing lazygit"
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"v*([^"]+)".*/\1/')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
sudo tar xf lazygit.tar.gz -C /usr/local/bin lazygit
rm lazygit.tar.gz

