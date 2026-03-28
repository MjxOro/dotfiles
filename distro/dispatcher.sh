#!/usr/bin/env bash
#
# distro/dispatcher.sh
# Operating system detection and dependency installation dispatcher
#
# This module detects the OS and dispatches to the appropriate distro-specific
# installation functions. It is sourced by the main install.sh.
#
# Dependencies:
#   - distro/macos.sh (for install_mac_dependencies)
#   - distro/arch.sh (for install_arch_dependencies)
#   - distro/debian.sh (for install_debian_dependencies)
#   - lib/logging.sh (for print_message, color codes)
#   - Global state: QUIET (defined by caller)
#
# API Contract:
#   - install_dependencies() is the main entry point
#   - Uses global QUIET for silent operation
#   - Detects macOS (Darwin) and Linux distributions via /etc/os-release
#   - Handles unsupported OS gracefully with error messages

# Source distro-specific modules
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/distro/macos.sh"
source "${SCRIPT_DIR}/distro/arch.sh"
source "${SCRIPT_DIR}/distro/debian.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

# -----------------------------------------------------------------------------
# Install dependencies based on OS detection
# -----------------------------------------------------------------------------
install_dependencies() {
  local os_name_detected=""
  local os_id_like=""
  local os_id=""
  local os_uname_s
  os_uname_s=$(uname -s)

  case "$os_uname_s" in
  Darwin)
    os_name_detected="macOS"
    install_mac_dependencies
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      os_id=$(. /etc/os-release && echo "$ID")
      os_id_like=$(. /etc/os-release && echo "$ID_LIKE")
      local os_pretty_name
      os_pretty_name=$(. /etc/os-release && echo "$PRETTY_NAME")
      if [[ "$os_id" == "debian" || "$os_id_like" == *"debian"* || "$os_id" == "ubuntu" ]]; then
        os_name_detected="Debian/Ubuntu ($os_pretty_name)"
        install_debian_dependencies
      elif [[ "$os_id" == "arch" || "$os_id_like" == *"arch"* ]]; then
        os_name_detected="Arch Linux ($os_pretty_name)"
        install_arch_dependencies
      else
        print_message "$RED" "Unsupported Linux distribution: $os_pretty_name (ID: $os_id)"
        print_message "$YELLOW" "Manual dependency installation may be needed."
      fi
    else
      print_message "$RED" "Unsupported Linux distribution (no /etc/os-release file found)."
    fi
    ;;
  *)
    print_message "$RED" "Unsupported operating system: $os_uname_s"
    ;;
  esac

  if [ "${QUIET:-false}" = false ] && [ -n "$os_name_detected" ]; then
    print_message "$GREEN" "Dependency check for $os_name_detected complete."
  fi
}
