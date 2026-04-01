#!/usr/bin/env bash
#
# install-pi-extension
# Install pi-mono/pi-agent extensions into OMP (Oh My Pi)
#
# Usage: install-pi-extension <source>
#   source can be:
#     - npm package: pi-multi-pass, @oh-my-pi/swarm-extension
#     - git repo: https://github.com/user/repo
#     - git shorthand: git:github.com/user/repo
#
# Examples:
#   install-pi-extension pi-multi-pass
#   install-pi-extension https://github.com/davebcn87/pi-autoresearch
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
PLUGINS_DIR="${HOME}/.omp/plugins"
NODE_MODULES="${PLUGINS_DIR}/node_modules"
FIX_SCRIPT="${PLUGINS_DIR}/scripts/fix-installed-plugins.mjs"

# Usage
usage() {
    cat << EOF
Usage: install-pi-extension <source>

Install pi-mono/pi-agent extensions into OMP.

Sources:
  npm package    pi-multi-pass, @oh-my-pi/swarm-extension
  git URL        https://github.com/user/repo
  git shorthand  git:github.com/user/repo

Examples:
  install-pi-extension pi-multi-pass
  install-pi-extension https://github.com/davebcn87/pi-autoresearch
  install-pi-extension git:github.com/davebcn87/pi-autoresearch

EOF
    exit 1
}

# Check dependencies
check_deps() {
    if ! command -v omp &> /dev/null; then
        echo -e "${RED}Error: omp not found in PATH${NC}"
        echo "Please install OMP first: https://oh-my-pi.io"
        exit 1
    fi
    
    if ! command -v bun &> /dev/null; then
        echo -e "${RED}Error: bun not found in PATH${NC}"
        echo "Please install Bun: https://bun.sh"
        exit 1
    fi
}

# Detect source type
detect_source_type() {
    local source="$1"
    
    if [[ "$source" == git:* ]] || [[ "$source" == http* ]] || [[ "$source" == ssh* ]]; then
        echo "git"
    elif [[ "$source" =~ ^[a-zA-Z0-9_-]+$ ]] || [[ "$source" =~ ^@[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        echo "npm"
    else
        echo "unknown"
    fi
}

# Extract package name from source
extract_package_name() {
    local source="$1"
    local source_type="$2"
    
    if [[ "$source_type" == "git" ]]; then
        # Extract from git URL
        basename "$source" .git
    else
        # npm package name
        echo "$source"
    fi
}

# Initialize plugins directory
init_plugins_dir() {
    if [[ ! -d "$PLUGINS_DIR" ]]; then
        echo -e "${BLUE}→ Creating plugins directory...${NC}"
        mkdir -p "$PLUGINS_DIR"
        mkdir -p "$NODE_MODULES"
    fi
    
    # Ensure package.json exists
    if [[ ! -f "$PLUGINS_DIR/package.json" ]]; then
        echo '{"name": "omp-plugins", "private": true, "dependencies": {}, "scripts": {"postinstall": "node ./scripts/fix-installed-plugins.mjs"}}' > "$PLUGINS_DIR/package.json"
    fi
    
    # Ensure scripts directory exists
    if [[ ! -d "$PLUGINS_DIR/scripts" ]]; then
        mkdir -p "$PLUGINS_DIR/scripts"
    fi
}

# Install via OMP plugin manager (npm only)
install_via_omp() {
    local package="$1"
    
    echo -e "${BLUE}→ Installing via omp plugin install...${NC}"
    
    if omp plugin install --dry-run "$package" 2>/dev/null; then
        omp plugin install "$package"
    else
        echo -e "${YELLOW}⚠ omp plugin install failed or not supported for this source${NC}"
        return 1
    fi
}

# Install via bun (git URLs and npm fallback)
install_via_bun() {
    local source="$1"
    
    echo -e "${BLUE}→ Installing with bun...${NC}"
    
    cd "$PLUGINS_DIR"
    
    if ! bun install "$source" 2>&1; then
        echo -e "${RED}✗ Installation failed${NC}"
        exit 1
    fi
}

# Check if installed package is a pi-mono extension
check_manifest() {
    local package_name="$1"
    local pkg_json="${NODE_MODULES}/${package_name}/package.json"
    
    if [[ ! -f "$pkg_json" ]]; then
        # Try scoped package
        local scope=$(dirname "$package_name")
        local name=$(basename "$package_name")
        if [[ "$scope" != "." ]] && [[ "$scope" != "$package_name" ]]; then
            pkg_json="${NODE_MODULES}/${scope}/${name}/package.json"
        fi
    fi
    
    if [[ ! -f "$pkg_json" ]]; then
        echo -e "${YELLOW}⚠ Warning: package.json not found${NC}"
        return 1
    fi
    
    # Check for pi or omp manifest
    if grep -q '"pi"' "$pkg_json" 2>/dev/null || grep -q '"omp"' "$pkg_json" 2>/dev/null; then
        echo -e "${GREEN}✓ Pi-mono/OMP extension detected${NC}"
        
        # Show manifest info
        local has_pi=$(grep -c '"pi"' "$pkg_json" 2>/dev/null || echo "0")
        local has_omp=$(grep -c '"omp"' "$pkg_json" 2>/dev/null || echo "0")
        
        if [[ "$has_pi" -gt 0 ]]; then
            echo -e "${BLUE}  Manifest: pi${NC}"
        fi
        if [[ "$has_omp" -gt 0 ]]; then
            echo -e "${BLUE}  Manifest: omp${NC}"
        fi
        
        return 0
    else
        echo -e "${YELLOW}⚠ Warning: No pi/omp manifest found${NC}"
        echo -e "${YELLOW}  This may not be a pi-mono extension${NC}"
        return 1
    fi
}

# Run compatibility patches
run_patches() {
    if [[ -f "$FIX_SCRIPT" ]]; then
        echo -e "${BLUE}→ Running compatibility patches...${NC}"
        if node "$FIX_SCRIPT" 2>&1; then
            echo -e "${GREEN}✓ Patches applied${NC}"
        else
            echo -e "${YELLOW}⚠ Some patches failed (this is OK for non-pi-mono packages)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Fix script not found, skipping patches${NC}"
    fi
}

# List what the extension provides
list_capabilities() {
    local package_name="$1"
    local pkg_dir="${NODE_MODULES}/${package_name}"
    
    echo ""
    echo -e "${CYAN}Extension capabilities:${NC}"
    
    # Skills
    if [[ -d "$pkg_dir/skills" ]]; then
        local skills=$(find "$pkg_dir/skills" -name "SKILL.md" -exec dirname {} \; 2>/dev/null | xargs -n1 basename 2>/dev/null | head -5)
        if [[ -n "$skills" ]]; then
            echo -e "${BLUE}  Skills:${NC}"
            echo "$skills" | while read skill; do
                echo "    • /skill:$skill"
            done
        fi
    fi
    
    # Commands
    if [[ -d "$pkg_dir/commands" ]]; then
        local commands=$(find "$pkg_dir/commands" -name "*.md" -exec basename {} .md \; 2>/dev/null | head -5)
        if [[ -n "$commands" ]]; then
            echo -e "${BLUE}  Commands:${NC}"
            echo "$commands" | while read cmd; do
                echo "    • /$cmd"
            done
        fi
    fi
    
    # Extensions
    if [[ -d "$pkg_dir/extensions" ]]; then
        local exts=$(find "$pkg_dir/extensions" -type f \( -name "*.ts" -o -name "*.js" \) -exec basename {} \; 2>/dev/null | head -5)
        if [[ -n "$exts" ]]; then
            echo -e "${BLUE}  Extensions:${NC}"
            echo "$exts" | while read ext; do
                echo "    • $ext"
            done
        fi
    fi
}

# Main install function
do_install() {
    local source="$1"
    local source_type=$(detect_source_type "$source")
    local package_name=$(extract_package_name "$source" "$source_type")
    
    echo -e "${CYAN}Installing: $source${NC}"
    echo -e "${BLUE}  Type: $source_type${NC}"
    echo -e "${BLUE}  Package: $package_name${NC}"
    echo ""
    
    # Initialize
    init_plugins_dir
    
    # Install based on source type
    if [[ "$source_type" == "npm" ]]; then
        # Try OMP plugin manager first
        if ! install_via_omp "$source"; then
            echo -e "${BLUE}→ Falling back to bun install...${NC}"
            install_via_bun "$source"
        fi
    elif [[ "$source_type" == "git" ]]; then
        install_via_bun "$source"
    else
        echo -e "${RED}Error: Unknown source type${NC}"
        echo "Source must be either:"
        echo "  - npm package name (e.g., pi-multi-pass)"
        echo "  - git URL (e.g., https://github.com/user/repo)"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ Installed to:${NC} ${NODE_MODULES}/${package_name}"
    echo ""
    
    # Check manifest
    check_manifest "$package_name"
    
    # Run patches
    run_patches
    
    # List capabilities
    list_capabilities "$package_name"
    
    # Final instructions
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Restart OMP or reload extensions"
    echo "  2. Verify with: omp plugin list"
    echo "  3. Check for issues: omp plugin doctor"
    echo ""
    echo -e "${YELLOW}Note: Some extensions may need additional configuration${NC}"
    echo -e "${YELLOW}      Check the extension's README for setup instructions${NC}"
}

# Main entry
main() {
    # Check args
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage
    fi
    
    local source="$1"
    
    # Check dependencies
    check_deps
    
    # Do install
    do_install "$source"
}

main "$@"
