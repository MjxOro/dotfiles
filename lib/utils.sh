#!/usr/bin/env bash
#
# lib/utils.sh
# Utility functions for the dotfiles installer
#

# ------------------------------------------------------------------------------
# Command & Path Utilities
# ------------------------------------------------------------------------------

# Check if a command exists in PATH
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Ensure bun's bin directory is on PATH
ensure_bun_bin_on_path() {
  local bun_bin_dir="$HOME/.bun/bin"
  if [ ! -d "$bun_bin_dir" ]; then
    return 0
  fi

  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

  case ":$PATH:" in
    *":$bun_bin_dir:"*) ;;
    *) export PATH="$bun_bin_dir:$PATH" ;;
  esac
}

# Check if a bun global command exists
# Fails gracefully if bun is not installed
bun_global_command_exists() {
  local command_name="$1"
  ensure_bun_bin_on_path
  command_exists "$command_name" || [ -x "$HOME/.bun/bin/$command_name" ]
}

# Resolve a path to its absolute form
# Works with or without realpath/perl - gracefully falls back
resolve_path() {
  local path="$1"
  if command_exists realpath; then
    realpath "$path" 2>/dev/null && return 0
  fi
  if command_exists perl; then
    perl -MCwd=realpath -e 'my $resolved = realpath(shift); exit 1 unless defined $resolved; print $resolved;' "$path" 2>/dev/null && return 0
  fi
  return 1
}
