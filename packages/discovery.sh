#!/usr/bin/env bash
#
# Package Discovery Module
#
# Functions for discovering available packages in the dotfiles repository.
#
# API Contract:
# - Depends on global variable LINK_SRC_BASE_DIR from cli/args.sh or install.sh
# - Functions assume required modules are already sourced
#

# Get list of available package directories
# Uses global variable LINK_SRC_BASE_DIR
# Returns: Sorted list of directory names (one per line)
get_available_packages() {
  # Exclude .git and other common VCS/temporary files/dirs from being listed as packages
  # Only include actual directories (not files)
  find "$LINK_SRC_BASE_DIR" -mindepth 1 -maxdepth 1 -type d \
    -not -path "$LINK_SRC_BASE_DIR/.git*" \
    -not -name ".DS_Store" \
    -not -name "docs" \
    -not -name "tools" \
    -not -name "lib" \
    -not -name "cli" \
    -not -name "packages" \
    -not -name "installers" \
    -not -name "distro" \
    -exec basename {} \; | sort
}
