# Agent Guidelines for Dotfiles Repository

## Build/Lint/Test Commands
- **Installation**: `./install.sh` - Main setup script for linking dotfiles and installing dependencies
- **Selective Installation**: `./install.sh -p nvim,zsh,tmux` - Install specific packages only
- **Neovim**: Uses LazyVim plugin manager; plugins auto-install on first Neovim launch
- **Link Only**: `./install.sh -l` - Only create symlinks without installing dependencies
- **Unlink**: `./install.sh -u` - Remove all managed dotfile symlinks

## Code Style Guidelines

### Shell Scripts (install.sh)
- Use `#!/usr/bin/env bash` shebang
- Enable strict error handling with `set -e`, `set -E`, `trap`
- Use meaningful variable names with underscores
- Color output using ANSI codes for better UX
- Provide clear error messages and exit codes

### Lua Configuration (nvim/)
- Follow LazyVim patterns and structure
- Use meaningful module names matching file paths
- Comment decisions with stylua ignore for formatting
- Use proper module returns and function definitions
- Keep plugin configurations self-contained

### General Configuration
- Maintain consistent indentation (2 spaces for Lua, standard for others)
- Use descriptive filenames following tool conventions
- Organize configurations by tool in separate directories
- Backup existing configs before overwriting

### Error Handling
- Provide helpful error messages with color-coded output
- Use proper exit codes (0 for success, 1 for failure)
- Implement graceful fallbacks for missing dependencies
- Log operations for debugging with VERBOSE=1

### Naming Conventions
- Directories: Use tool names (nvim/, zsh/, tmux/, starship/)
- Configuration files: Follow tool defaults (.zshrc, .tmux.conf)
- Variables: snake_case for shell, camelCase where appropriate for Lua