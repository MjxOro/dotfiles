#!/usr/bin/env bash
# lib/paths.sh - Path resolution and SCRIPT_DIR logic
# This module handles robust script directory initialization

# --- Robust SCRIPT_DIR Initialization ---
# When sourced from install.sh: uses caller's BASH_SOURCE[1] to get install.sh's dir
# When executed directly or tested interactively: uses BASH_SOURCE[0]
set +e

# Determine the source script path
# BASH_SOURCE[1] is the file that sourced this one (install.sh)
# BASH_SOURCE[0] is this file (paths.sh) when sourced, or itself when executed
if [[ -n "${BASH_SOURCE[1]:-}" ]] && [[ -f "${BASH_SOURCE[1]}" ]]; then
  SCRIPT_SOURCE="${BASH_SOURCE[1]}"
elif [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_SOURCE="${BASH_SOURCE[0]}"
else
  echo -e "\033[0;31mFATAL ERROR: BASH_SOURCE is empty. Cannot determine script directory.\033[0m" >&2
  return 1 2>/dev/null || exit 1
fi

# Validate we got a path
if [[ -z "$SCRIPT_SOURCE" ]]; then
  echo -e "\033[0;31mFATAL ERROR: Could not determine source script path.\033[0m" >&2
  return 1 2>/dev/null || exit 1
fi

# Resolve to absolute directory path
# Handles spaces in paths via proper quoting
SCRIPT_DIR_TEMP="$(cd "$(dirname -- "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
SCRIPT_DIR_EXIT_CODE=$?

set -e

# Validate the result
if [[ $SCRIPT_DIR_EXIT_CODE -ne 0 ]] || [[ -z "$SCRIPT_DIR_TEMP" ]] || [[ ! -d "$SCRIPT_DIR_TEMP" ]]; then
  echo -e "\033[0;31mFATAL ERROR: Failed to determine script directory from: $SCRIPT_SOURCE\033[0m" >&2
  return 1 2>/dev/null || exit 1
fi

# Export the result
SCRIPT_DIR="$SCRIPT_DIR_TEMP"
export SCRIPT_DIR

# Debug output if VERBOSE is enabled
if [[ "${VERBOSE:-0}" == "1" ]]; then
  echo -e "\033[0;36mDEBUG: Script directory determined as: $SCRIPT_DIR\033[0m" >&2
fi

# --- End of SCRIPT_DIR Initialization ---
