# Dotfiles

A simple and customizable dotfiles management system with automatic dependency detection for different operating systems.

## Features

- Automatic symlinking of configuration files
- Cross-platform support (macOS, Debian/Ubuntu, Arch Linux)
- Selective package installation/linking
- Automatic dependency management
- Interactive and non-interactive modes
- Backup of existing configurations

## Directory Structure

The repository follows a simple structure:

```
dotfiles/
├── nvim/              # NeoVim configuration (links to ~/.config/nvim/)
├── starship/          # Starship prompt config (links to ~/.config/starship/)
├── tmux/              # Tmux configuration
│   └── .tmux.conf     # Links to ~/.tmux.conf
├── zsh/               # Zsh configuration
│   └── .zshrc         # Links to ~/.zshrc
└── install.sh         # Installation script
```

## Installation

### Quick Start

```bash
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
./install.sh
```

### Options

```
Usage: ./install.sh [OPTIONS]

Options:
  -h, --help           Show this help message
  -d, --dotfiles-dir   Specify dotfiles directory (default: script location)
  -l, --link-only      Only link dotfiles, don't install dependencies
  -u, --unlink         Unlink dotfiles for specified packages (or all)
  -y, --yes            Assume yes for all prompts (use with caution)
  -i, --interactive    Force interactive mode for prompts (default if TTY)
  -q, --quiet          Minimize output
  -p, --packages       Comma-separated list of packages to link/unlink (default: all)
                       (e.g., nvim,tmux,zsh)
```

### Examples

Link only specific packages:
```bash
./install.sh -p nvim,zsh
```

Unlink all managed dotfiles:
```bash
./install.sh -u
```

Only link dotfiles without installing dependencies:
```bash
./install.sh -l
```

Non-interactive installation (assumes yes to all prompts):
```bash
./install.sh -y
```

## Linking Rules

The script follows these rules for linking:

1. Top-level non-dot-prefixed directories (like nvim, starship) link to ~/.config/
2. Specific dotfiles (.zshrc, .tmux, .tmux.conf) inside package directories link to $HOME

## Dependencies

The script can automatically install these dependencies based on your OS:

- **All platforms**: git, curl, zsh
- **macOS**: Xcode Command Line Tools, Homebrew (optional)
- **Debian/Ubuntu**: build-essential, software-properties-common
- **Arch Linux**: base-devel packages

Optional tools:
- Starship prompt
- Oh My Zsh
- Neovim (with unstable PPA option for Debian/Ubuntu)

## Customization

To add a new package:

1. Create a new directory in the dotfiles repo, e.g., `foo/`
2. Put configuration files in it
3. Run `./install.sh -p foo` to link only this package or `./install.sh` to link all

### Machine-specific overrides (avoid merge conflicts)

Keep shared defaults in tracked files, and put per-machine values in `zsh/secrets.zsh`.

1. Copy `zsh/secrets.example.zsh` to `zsh/secrets.zsh`
2. Add host/user specific paths and env vars there
3. Keep `.zshrc` generic (`$HOME`, conditional path checks) so shared config stays merge-friendly

`zsh/secrets.zsh` is gitignored, so local changes do not create branch conflicts.

## OS Support

- **macOS**: Fully supported, uses Homebrew when available
- **Debian/Ubuntu**: Fully supported with apt
- **Arch Linux**: Fully supported with pacman
- **Other Linux**: Basic support, dependencies may need manual installation

## Troubleshooting

- Run with `-i` for interactive mode to see what's happening
- Check the script output for error messages
- Run with verbose debug by using: `VERBOSE=1 ./install.sh`
- Look for backups in `~/.dotfiles_backup/` if you need to restore configuration

## License

This project is licensed under the MIT License - see the LICENSE file for details.
