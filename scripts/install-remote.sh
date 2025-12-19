#!/bin/bash
# install-remote.sh - One-liner installation for claude-sudo-tools
# https://github.com/hugsband/claude-sudo-tools
#
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/hugsband/claude-sudo-tools/main/scripts/install-remote.sh)

set -euo pipefail

REPO="hugsband/claude-sudo-tools"
BRANCH="main"
TEMP_DIR=$(mktemp -d)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo -e "${CYAN}=== Claude Code Sudo Tools - Remote Installer ===${NC}"
echo

# Check for required tools
for cmd in curl git; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}ERROR: $cmd is required but not installed.${NC}" >&2
        exit 1
    fi
done

echo "Downloading claude-sudo-tools..."
git clone --depth 1 "https://github.com/$REPO.git" "$TEMP_DIR" 2>/dev/null

echo "Running installer..."
cd "$TEMP_DIR"
./scripts/install.sh "$@"

echo
echo -e "${GREEN}Installation complete!${NC}"
echo "Run 'claude-sudo' to start Claude Code with sudo access."
