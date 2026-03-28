#!/bin/bash
# ============================================================================
# Logging Module
# ============================================================================
# Provides colored output functions and ANSI color code definitions.
# Source this file: source "${SCRIPT_DIR}/lib/logging.sh"
# ============================================================================

# ANSI color codes
export BOLD='\033[1m'
export UNDERLINE='\033[4m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export GRAY='\033[0;90m'
export NC='\033[0m' # No Color

# Function to print colored messages
# Usage: print_message "$GREEN" "Success message"
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Function to print section header
# Usage: print_header "Section Title"
print_header() {
  echo
  print_message "$PURPLE" "========== $1 =========="
  echo
}
