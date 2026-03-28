#!/bin/bash
#
# Help output module for install.sh
# Displays usage information and available options
#

# Function to display help message
show_help() {
  echo -e "${BOLD}Dotfiles Installation Script${NC}"
  echo
  echo "Usage: ./install.sh [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help           Show this help message"
  echo "  -d, --dotfiles-dir   Specify dotfiles directory (default: script location)"
  echo "  -l, --link-only      Only link dotfiles, don't install dependencies"
  echo "  -u, --unlink         Unlink dotfiles for specified packages (or all)"
  echo "  -y, --yes            Assume yes for all prompts (use with caution)"
  echo "  -i, --interactive    Force interactive mode for prompts (default if TTY)"
  echo "  -q, --quiet          Minimize output"
  echo "  -p, --packages       Comma-separated list of packages to link/unlink (default: all)"
  echo "                       (e.g., nvim,tmux,zsh)"
  echo "      --install-nvm    Enable optional nvm installation (default: off)"
  echo
  echo "Environment Variables:"
  echo "  VERBOSE=1            Enable verbose debug output"
  echo
  echo "Example:"
  echo "  ./install.sh -d ~/my-dotfiles -p nvim,zsh"
  echo "  ./install.sh -u       # Unlink all managed dotfiles"
  echo "  VERBOSE=1 ./install.sh # Run with debug output"
}
