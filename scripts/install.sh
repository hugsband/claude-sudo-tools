#!/bin/bash
# install.sh - Install claude-sudo-tools
# https://github.com/hugsband/claude-sudo-tools
#
# Installs GUI-based sudo authentication for Claude Code CLI.
# Version: 1.0.0

set -euo pipefail

VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
SUDOERS_FILE="/etc/sudoers.d/claude-sudo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
install.sh - Install claude-sudo-tools

USAGE
    ./install.sh [OPTIONS]

OPTIONS
    -h, --help      Show this help message
    -v, --version   Show version number
    --timeout MIN   Set sudo timeout in minutes (default: 90)

DESCRIPTION
    Installs claude-sudo and claude-askpass to /usr/local/bin/
    Configures sudo credential caching for your user.

REQUIREMENTS
    - Claude Code CLI (claude command)
    - GUI dialog tool: kdialog, zenity, yad, or ssh-askpass
    - sudo access

EOF
}

show_version() {
    echo "claude-sudo-tools installer version $VERSION"
}

# Default timeout
TIMEOUT_MINUTES=90

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        --timeout)
            TIMEOUT_MINUTES="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            show_help
            exit 1
            ;;
    esac
done

echo -e "${CYAN}=== Claude Code Sudo Tools Installer v$VERSION ===${NC}"
echo

# Check for root/sudo
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}ERROR: Don't run as root. Script will use sudo when needed.${NC}" >&2
    exit 1
fi

# Check claude is installed
if ! command -v claude &>/dev/null; then
    echo -e "${YELLOW}WARNING: 'claude' command not found in PATH${NC}"
    echo "Make sure Claude Code is installed before using claude-sudo"
    echo "  Install: npm install -g @anthropic-ai/claude-code"
    echo
fi

# Check for GUI dialog tool
echo "Checking for GUI dialog tools..."
GUI_TOOL=""
for tool in kdialog zenity yad ssh-askpass; do
    if command -v $tool &>/dev/null; then
        GUI_TOOL=$tool
        echo -e "  Found: ${GREEN}$tool${NC}"
        break
    fi
done

if [[ -z "$GUI_TOOL" ]]; then
    echo -e "${RED}ERROR: No GUI dialog tool found!${NC}" >&2
    echo "" >&2
    echo "Install one of the following:" >&2
    echo "  Fedora/Nobara: sudo dnf install kdialog   # or zenity" >&2
    echo "  Ubuntu/Debian: sudo apt install zenity" >&2
    echo "  Arch Linux:    sudo pacman -S zenity" >&2
    exit 1
fi

# Check bin directory exists
if [[ ! -d "$BIN_DIR" ]]; then
    echo -e "${RED}ERROR: bin/ directory not found at $BIN_DIR${NC}" >&2
    echo "Make sure you're running from the claude-sudo-tools directory." >&2
    exit 1
fi

echo
echo "Installing scripts to $INSTALL_DIR..."

# Install askpass
sudo install -m 755 "$BIN_DIR/claude-askpass" "$INSTALL_DIR/claude-askpass"
echo -e "  Installed: ${GREEN}claude-askpass${NC}"

# Install wrapper
sudo install -m 755 "$BIN_DIR/claude-sudo" "$INSTALL_DIR/claude-sudo"
echo -e "  Installed: ${GREEN}claude-sudo${NC}"

echo
echo "Configuring sudo (${TIMEOUT_MINUTES}-minute timeout, shared across terminals)..."

# Create sudoers entry with !tty_tickets to share credentials across terminals
CURRENT_USER=$(whoami)
SUDOERS_CONTENT="# Claude Code sudo configuration
# Installed by claude-sudo-tools v$VERSION
# https://github.com/hugsband/claude-sudo-tools
#
# timestamp_timeout: Credentials cached for $TIMEOUT_MINUTES minutes
# !tty_tickets: Share credentials across all terminals (required for Claude)
Defaults:$CURRENT_USER timestamp_timeout=$TIMEOUT_MINUTES, !tty_tickets"

echo "$SUDOERS_CONTENT" | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 440 "$SUDOERS_FILE"

# Validate sudoers syntax
if sudo visudo -c -f "$SUDOERS_FILE" &>/dev/null; then
    echo -e "  Sudoers configuration: ${GREEN}valid${NC}"
else
    echo -e "${RED}ERROR: Invalid sudoers syntax!${NC}" >&2
    sudo rm -f "$SUDOERS_FILE"
    exit 1
fi

echo
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo
echo "Usage:"
echo -e "  ${CYAN}claude-sudo${NC}        # Run Claude with sudo access"
echo -e "  ${CYAN}claude-sudo --help${NC} # Show help"
echo
echo "Your sudo credentials will be cached for $TIMEOUT_MINUTES minutes."
echo "A GUI password prompt will appear on first sudo command."
