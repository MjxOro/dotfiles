# Dotfiles

A minimalist, cross-platform dotfiles manager with a single script to handle everything.

## Features

- **Single Script** - One file to handle installation, linking, and uninstallation
- **Cross-Platform** - Works on macOS, Debian/Ubuntu, and Arch Linux
- **Interactive UI** - Select which dotfiles to install with a friendly menu
- **Smart Backups** - Automatically backs up existing configurations
- **Package Handling** - Installs all necessary dependencies for your setup
- **Idempotent** - Run it multiple times without breaking anything

## Structure

```
dotfiles/
├── install.sh            # The all-in-one installation script
└── stow/                 # Dotfiles organized by application
    ├── nvim/             # Neovim configuration
    │   └── .config/nvim/ # Files will be linked to ~/.config/nvim/
    ├── tmux/             # Tmux configuration
    ├── zsh/              # Zsh configuration
    └── starship/         # Starship prompt configuration
```

## Quick Install

```bash
# Clone the repository
git clone https://github.com/YourUsername/dotfiles.git

# Navigate to the dotfiles directory
cd dotfiles

# Make the script executable
chmod +x install.sh

# Run the installer
./install.sh
```

## Usage

The script has several options for flexible usage:

```bash
Usage: ./install.sh [OPTIONS]

Options:
  -h, --help           Show this help message
  -d, --dotfiles-dir   Specify dotfiles directory (default: script location)
  -l, --link-only      Only link dotfiles, don't install dependencies
  -u, --unlink         Unlink dotfiles
  -y, --yes            Assume yes for all prompts
  -i, --interactive    Force interactive mode (default in TTY)
  -q, --quiet          Minimize output
  -p, --packages       Comma-separated list of packages to link (default: all)
```

### Examples

**Full Installation (Interactive)**
```bash
./install.sh
```

**Link Only Without Installing Dependencies**
```bash
./install.sh --link-only
```

**Install Specific Packages Only**
```bash
./install.sh --packages nvim,tmux
```

**Unlink All Dotfiles**
```bash
./install.sh --unlink
```

**Non-Interactive Installation**
```bash
./install.sh --yes
```

**Specify Dotfiles Location**
```bash
./install.sh --dotfiles-dir /path/to/dotfiles
```

## What Gets Installed

The script will install the following based on your operating system:

### macOS
- Homebrew (if missing)
- Neovim
- Tmux and Tmux Plugin Manager
- Starship prompt
- Node Version Manager (NVM)
- Lazygit
- Utilities: ripgrep, fd, fzf, bat, exa, jq, gh
- Nerd Fonts (optional)

### Debian/Ubuntu and Arch Linux
- Zsh
- Oh My Zsh
- Neovim
- Tmux and Tmux Plugin Manager
- Starship prompt
- Node Version Manager (NVM)
- Lazygit

## Customization

Each folder in the `stow` directory represents a package of configuration files that will be symlinked to your home directory.

To add your own configurations:

1. Create a new folder in the `stow` directory (e.g., `stow/mytool/`)
2. Place your configuration files inside, maintaining the structure relative to your home directory
3. Run `./install.sh -l -p mytool` to link only your new package

## Troubleshooting

- If you encounter permission issues, ensure the script is executable: `chmod +x install.sh`
- Check the backup directory (`~/.dotfiles_backup/`) for any files that were replaced during installation
- If you're having issues with a specific package, try running with just that package: `./install.sh -p specific_package`
- For verbose output, use the `-i` flag to force interactive mode
