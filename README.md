# claude-sudo-tools

> On-demand sudo access for [Claude Code](https://claude.com/claude-code) CLI on Linux systems.

**Why this utility?** You could run Claude as root or configure passwordless sudo—but both remove important security barriers. This tool lets you authenticate once per session via GUI prompt, with time-limited credential caching and full audit logging. No permanent privilege escalation, no wide-open sudoers rules.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-green.svg)](#requirements)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-yellow.svg)](#requirements)

## The Problem

Claude Code runs commands without a TTY (terminal), so `sudo` commands fail:

```
sudo: a terminal is required to read the password
```

This prevents Claude from running system administration tasks, installing packages, or modifying system files.

## The Solution

**claude-sudo-tools** provides:

1. **GUI Authentication** - Password prompt via kdialog/zenity (no terminal needed)
2. **Credential Caching** - Authenticate once, cached for 90 minutes
3. **Session Management** - Background process keeps credentials fresh during your session
4. **Clean Exit** - Background processes cleaned up when you close Claude

## Quick Install

**One-liner:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/hugsband/claude-sudo-tools/main/scripts/install-remote.sh)
```

**Or clone and install:**
```bash
git clone https://github.com/hugsband/claude-sudo-tools.git
cd claude-sudo-tools
./scripts/install.sh
```

## Usage

```bash
# Start Claude with sudo access
claude-sudo

# Pass arguments to Claude
claude-sudo /path/to/project

# Show help
claude-sudo --help
```

When you run `claude-sudo`, a GUI password dialog appears once. After that, all `sudo` commands work without prompts for 90 minutes.

### Example Session

```
$ claude-sudo
Authenticating for sudo access...
[GUI password prompt appears]
Authentication successful.

╭─── Claude Code ─────────────────────────╮
│          Welcome back!                  │
╰─────────────────────────────────────────╯

> Install htop for me
● sudo dnf install htop
  ⎿ [installs without password prompt]
```

## How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────┐
│  claude-sudo    │────▶│  claude-askpass  │────▶│ GUI Dialog  │
│  (wrapper)      │     │  (password)      │     │ (kdialog)   │
└────────┬────────┘     └──────────────────┘     └─────────────┘
         │
         │ sudo -A -v (authenticate)
         ▼
┌─────────────────┐     ┌──────────────────┐
│  keepalive      │────▶│  sudo timestamp  │
│  (background)   │     │  (90 min cache)  │
└────────┬────────┘     └──────────────────┘
         │
         │ exec claude
         ▼
┌─────────────────┐
│  Claude Code    │
│  (with sudo)    │
└─────────────────┘
```

1. `claude-sudo` sets `SUDO_ASKPASS` to use GUI prompts
2. Initial `sudo -A -v` triggers password dialog
3. Background keepalive refreshes credentials every 4 minutes
4. Claude runs with working sudo access
5. On exit, keepalive process terminates

## Requirements

### Operating Systems

| Distro | Status | Notes |
|--------|--------|-------|
| Fedora / Nobara | ✅ Tested | Primary development platform |
| Ubuntu / Debian | ✅ Should work | Install zenity: `sudo apt install zenity` |
| Arch Linux | ✅ Should work | Install zenity: `sudo pacman -S zenity` |
| Other systemd Linux | ⚠️ Untested | Should work if requirements met |

### Dependencies

| Requirement | Purpose |
|-------------|---------|
| `claude` | Claude Code CLI ([install](https://claude.com/claude-code)) |
| `bash` | Shell (version 4.0+) |
| `sudo` | Privilege escalation |
| GUI dialog | One of: `kdialog`, `zenity`, `yad`, `ssh-askpass` |

**Install a GUI dialog tool:**
```bash
# Fedora/Nobara (KDE)
sudo dnf install kdialog

# Fedora/Nobara (GNOME)
sudo dnf install zenity

# Ubuntu/Debian
sudo apt install zenity

# Arch Linux
sudo pacman -S zenity
```

## Configuration

### Custom Timeout

Default credential timeout is 90 minutes. To change:

```bash
./scripts/install.sh --timeout 60  # 60 minutes
```

Or manually edit `/etc/sudoers.d/claude-sudo`:
```
Defaults:YOUR_USER timestamp_timeout=60, !tty_tickets
```

### Files Installed

| File | Location | Purpose |
|------|----------|---------|
| `claude-sudo` | `/usr/local/bin/` | Main wrapper command |
| `claude-askpass` | `/usr/local/bin/` | GUI password helper |
| sudoers config | `/etc/sudoers.d/claude-sudo` | Timeout & tty settings |

## Troubleshooting

### Password prompt on every command

**Cause:** `tty_tickets` is enabled (default), isolating credentials per-terminal.

**Fix:** The installer should set `!tty_tickets` automatically. If not:
```bash
sudo visudo -f /etc/sudoers.d/claude-sudo
```
Ensure it contains:
```
Defaults:YOUR_USER timestamp_timeout=90, !tty_tickets
```

### "No GUI dialog tool found"

**Fix:** Install a dialog tool:
```bash
sudo dnf install kdialog  # or zenity
```

### "claude command not found"

**Fix:** Install Claude Code CLI:
```bash
npm install -g @anthropic-ai/claude-code
```

### Check for orphaned processes

If you're upgrading from version 1.0.0, check for orphaned processes:
```bash
ps aux | grep claude-sudo | grep -v grep
```

The uninstaller automatically cleans these up, or manually kill them:
```bash
pkill -f "/usr/local/bin/claude-sudo"
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more issues.

## Security

- **No passwords stored** - Sudo uses timestamp files, not credential caching
- **No NOPASSWD** - You must authenticate each session
- **Audit trail** - All sudo usage logged to `/var/log/auth.log`
- **Session-scoped** - Credentials cleared when Claude exits

See [docs/SECURITY.md](docs/SECURITY.md) for detailed security information.

## Uninstall

```bash
./scripts/uninstall.sh
```

Or manually:
```bash
sudo rm /usr/local/bin/claude-sudo /usr/local/bin/claude-askpass
sudo rm /etc/sudoers.d/claude-sudo
```

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related

- [Claude Code](https://claude.com/claude-code) - AI coding assistant CLI
- [Anthropic](https://anthropic.com) - Creators of Claude
