#!/bin/bash
# uninstall.sh - Remove claude-sudo-tools
# https://github.com/hugsband/claude-sudo-tools

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Uninstalling Claude Code Sudo Tools ===${NC}"
echo

# Check for root/sudo
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}ERROR: Don't run as root. Script will use sudo when needed.${NC}" >&2
    exit 1
fi

# Remove installed files
echo "Removing installed files..."

if [[ -f /usr/local/bin/claude-askpass ]]; then
    sudo rm -f /usr/local/bin/claude-askpass
    echo -e "  Removed: ${GREEN}claude-askpass${NC}"
else
    echo -e "  Not found: ${YELLOW}claude-askpass${NC} (skipped)"
fi

if [[ -f /usr/local/bin/claude-sudo ]]; then
    sudo rm -f /usr/local/bin/claude-sudo
    echo -e "  Removed: ${GREEN}claude-sudo${NC}"
else
    echo -e "  Not found: ${YELLOW}claude-sudo${NC} (skipped)"
fi

if [[ -f /etc/sudoers.d/claude-sudo ]]; then
    sudo rm -f /etc/sudoers.d/claude-sudo
    echo -e "  Removed: ${GREEN}sudoers config${NC}"
else
    echo -e "  Not found: ${YELLOW}sudoers config${NC} (skipped)"
fi

echo
echo -e "${GREEN}=== Uninstall Complete ===${NC}"
echo
echo "Your default sudo timeout has been restored."
echo "You can now use 'claude' directly (without sudo access)."
