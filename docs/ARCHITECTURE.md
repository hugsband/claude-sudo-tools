# Architecture

Technical internals of claude-sudo-tools for developers and AI assistants.

## Table of Contents

- [Component Overview](#component-overview)
- [Data Flow](#data-flow)
- [File Locations](#file-locations)
- [Script Internals](#script-internals)
- [Sudo Integration](#sudo-integration)
- [Extension Points](#extension-points)

---

## Component Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        claude-sudo-tools                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐ │
│  │ claude-sudo │───▶│claude-askpass│───▶│   GUI Dialog           │ │
│  │  (wrapper)  │    │ (askpass)   │    │ (kdialog/zenity/yad)   │ │
│  └──────┬──────┘    └─────────────┘    └─────────────────────────┘ │
│         │                                                           │
│         │ sets SUDO_ASKPASS                                         │
│         │ calls sudo -A -v                                          │
│         │ spawns keepalive                                          │
│         │ exec claude                                               │
│         ▼                                                           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐ │
│  │  keepalive  │───▶│    sudo     │───▶│   /run/sudo/ts/$USER   │ │
│  │ (background)│    │ (timestamp) │    │   (timestamp file)     │ │
│  └─────────────┘    └─────────────┘    └─────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Components

| Component | File | Purpose |
|-----------|------|---------|
| Wrapper | `bin/claude-sudo` | Entry point, orchestrates authentication |
| Askpass | `bin/claude-askpass` | GUI password prompt |
| Installer | `scripts/install.sh` | Deploys files, configures sudoers |
| Uninstaller | `scripts/uninstall.sh` | Removes all installed files |
| Remote Installer | `scripts/install-remote.sh` | One-liner installation support |

---

## Data Flow

### Startup Sequence

```
User runs: claude-sudo [args]
        │
        ▼
┌───────────────────────────────────────┐
│ 1. Parse arguments                     │
│    - --help, --version handled here   │
│    - Other args passed to claude      │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│ 2. Verify claude-askpass exists       │
│    - Check /usr/local/bin/claude-askpass│
│    - Exit with error if missing       │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│ 3. Set SUDO_ASKPASS environment       │
│    export SUDO_ASKPASS=/usr/local/bin/│
│           claude-askpass              │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│ 4. Check existing credentials         │
│    sudo -n true                       │
│    - If success: skip auth            │
│    - If fail: proceed to auth         │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│ 5. Authenticate via GUI               │
│    sudo -A -v                         │
│    - -A: use askpass                  │
│    - -v: validate only (no command)   │
│    - Triggers claude-askpass          │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│ 6. Start keepalive process            │
│    keepalive() & → KEEPALIVE_PID      │
│    - Runs in background               │
│    - Sleeps 240s, calls sudo -A -v    │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│ 7. Set up cleanup trap                │
│    trap cleanup EXIT INT TERM HUP     │
│    - Kills keepalive on exit          │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│ 8. Execute Claude                     │
│    exec claude "$@"                   │
│    - Replaces current process         │
│    - Passes all arguments             │
└───────────────────────────────────────┘
```

### Authentication Flow (claude-askpass)

```
sudo calls SUDO_ASKPASS
        │
        ▼
┌───────────────────────────────────────┐
│ 1. Check for kdialog                  │
│    command -v kdialog                 │
│    - If found: use kdialog            │
└───────────────────┬───────────────────┘
                    │ not found
                    ▼
┌───────────────────────────────────────┐
│ 2. Check for zenity                   │
│    command -v zenity                  │
│    - If found: use zenity             │
│    - Has 60s timeout                  │
└───────────────────┬───────────────────┘
                    │ not found
                    ▼
┌───────────────────────────────────────┐
│ 3. Check for yad                      │
│    command -v yad                     │
│    - If found: use yad                │
│    - Has 60s timeout                  │
└───────────────────┬───────────────────┘
                    │ not found
                    ▼
┌───────────────────────────────────────┐
│ 4. Check for ssh-askpass              │
│    command -v ssh-askpass             │
│    - Fallback option                  │
└───────────────────┬───────────────────┘
                    │ not found
                    ▼
┌───────────────────────────────────────┐
│ 5. Error: No GUI tool available       │
│    Exit 1 with instructions           │
└───────────────────────────────────────┘
```

### Keepalive Loop

```
┌─────────────────────────────────────┐
│         Keepalive Process           │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────┐                        │
│  │  Start  │                        │
│  └────┬────┘                        │
│       │                             │
│       ▼                             │
│  ┌─────────────┐                    │
│  │ sleep 240s  │ ◀──────────────┐   │
│  │ (4 minutes) │                │   │
│  └──────┬──────┘                │   │
│         │                       │   │
│         ▼                       │   │
│  ┌─────────────────┐            │   │
│  │ sudo -A -v      │            │   │
│  │ (refresh creds) │            │   │
│  └────────┬────────┘            │   │
│           │                     │   │
│     ┌─────┴─────┐               │   │
│     │           │               │   │
│  success     failure            │   │
│     │           │               │   │
│     │        ┌──▼──┐            │   │
│     │        │exit 0│           │   │
│     │        └──────┘           │   │
│     │                           │   │
│     └───────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## File Locations

### Source Repository

```
claude-sudo-tools/
├── bin/
│   ├── claude-sudo          # Main wrapper script
│   └── claude-askpass       # GUI password helper
├── scripts/
│   ├── install.sh           # Local installer
│   ├── uninstall.sh         # Uninstaller
│   └── install-remote.sh    # Remote/curl installer
├── docs/
│   ├── ARCHITECTURE.md      # This file
│   ├── SECURITY.md          # Security documentation
│   └── TROUBLESHOOTING.md   # Common issues
├── README.md                # Main documentation
├── CONTRIBUTING.md          # Contribution guidelines
├── CHANGELOG.md             # Version history
├── LICENSE                  # MIT License
├── .gitignore               # Git ignore patterns
└── llms.txt                 # AI documentation index
```

### Installed Files

| Source | Destination | Permissions |
|--------|-------------|-------------|
| `bin/claude-sudo` | `/usr/local/bin/claude-sudo` | 755 |
| `bin/claude-askpass` | `/usr/local/bin/claude-askpass` | 755 |
| (generated) | `/etc/sudoers.d/claude-sudo` | 440 |

### Runtime Files

| File | Purpose | Created By |
|------|---------|------------|
| `/run/sudo/ts/$USER` | Sudo timestamp cache | sudo |
| `/var/log/auth.log` | Sudo audit log | sudo/syslog |

---

## Script Internals

### claude-sudo Variables

```bash
VERSION="1.0.0"              # Script version
ASKPASS="/usr/local/bin/claude-askpass"  # Path to askpass helper
KEEPALIVE_INTERVAL=240       # Seconds between keepalive (4 min)
KEEPALIVE_PID                # PID of background keepalive process
```

### claude-sudo Functions

```bash
show_help()      # Display usage information
show_version()   # Display version number
keepalive()      # Background credential refresh loop
cleanup()        # Kill keepalive process on exit
```

### claude-askpass Variables

```bash
TITLE="Claude Code - Authentication Required"  # Dialog title
PROMPT="Enter sudo password:"                  # Dialog prompt
TIMEOUT=60                                     # Dialog timeout (seconds)
```

### install.sh Variables

```bash
VERSION="1.0.0"                        # Installer version
INSTALL_DIR="/usr/local/bin"           # Binary installation directory
SUDOERS_FILE="/etc/sudoers.d/claude-sudo"  # Sudoers config path
SCRIPT_DIR                             # Directory containing install.sh
BIN_DIR                                # Directory containing binaries
TIMEOUT_MINUTES=90                     # Default credential timeout
```

---

## Sudo Integration

### Sudoers Configuration

Generated by installer:

```
# /etc/sudoers.d/claude-sudo
# Claude Code sudo configuration
# Installed by claude-sudo-tools v1.0.0

Defaults:username timestamp_timeout=90, !tty_tickets
```

#### Options Explained

| Option | Value | Purpose |
|--------|-------|---------|
| `timestamp_timeout` | 90 | Minutes before credentials expire |
| `!tty_tickets` | (disabled) | Share credentials across terminals |

### SUDO_ASKPASS Mechanism

1. When `SUDO_ASKPASS` environment variable is set
2. And `sudo -A` is used (or `sudo` fails to get password from terminal)
3. Sudo executes the program specified in `SUDO_ASKPASS`
4. The program must output the password to stdout
5. Sudo reads the password and verifies it

### Timestamp File Structure

```
/run/sudo/ts/
└── username           # Per-user timestamp file (binary)
```

The timestamp file contains:
- Version number
- User UID
- Session ID
- Timestamp of last successful auth
- Various flags

Managed entirely by sudo - we don't read or modify it directly.

---

## Extension Points

### Adding New Dialog Tools

In `bin/claude-askpass`, add before the error block:

```bash
elif command -v newdialog &>/dev/null; then
    newdialog --password-option "$PROMPT"
```

### Custom Timeout

1. **At install time:**
   ```bash
   ./scripts/install.sh --timeout 60
   ```

2. **Post-install:**
   ```bash
   sudo visudo -f /etc/sudoers.d/claude-sudo
   # Change timestamp_timeout value
   ```

### Alternative Commands

To wrap a different command instead of `claude`:

```bash
# In claude-sudo, change:
exec claude "$@"

# To:
exec your-command "$@"
```

### Debugging

Enable bash debug mode:

```bash
# Run with tracing
bash -x /usr/local/bin/claude-sudo

# Or add to script:
set -x  # Enable debug
set +x  # Disable debug
```

### Logging

Add logging to claude-sudo:

```bash
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> /tmp/claude-sudo.log
}

log "Starting claude-sudo"
log "Authenticating..."
```

---

## Version History

See [CHANGELOG.md](../CHANGELOG.md) for version history.

---

## See Also

- [README.md](../README.md) - User documentation
- [SECURITY.md](SECURITY.md) - Security considerations
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [sudo(8)](https://man7.org/linux/man-pages/man8/sudo.8.html) - Sudo manual
- [sudoers(5)](https://man7.org/linux/man-pages/man5/sudoers.5.html) - Sudoers manual
