# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Fixed
- Nothing yet

---

## [1.0.2] - 2025-12-21

### Fixed
- Keepalive now detects parent process death (handles SIGKILL edge case)
- Orphaned keepalive processes self-terminate when parent is killed

### Changed
- Added prominent "Why this utility?" note to README explaining benefits vs running as root or passwordless sudo

---

## [1.0.1] - 2025-12-20

### Fixed
- **CRITICAL:** Fixed keepalive process orphaning - changed from `exec claude` to `claude` to preserve cleanup trap
- Improved keepalive error handling with clearer logic
- Enhanced cleanup function to properly wait for background processes
- Added orphaned process cleanup to uninstall script

### Changed
- Updated documentation to accurately reflect cleanup behavior
- Added timeout validation (1-1440 minutes) to install script
- Updated ARCHITECTURE.md to reflect process management changes

### Security
- Orphaned processes no longer indefinitely refresh sudo credentials after Claude exits
- Improved process lifecycle management prevents credential persistence beyond session

---

## [1.0.0] - 2025-12-19

### Added
- Initial release
- `claude-sudo` wrapper script for running Claude Code with sudo access
- `claude-askpass` GUI password helper supporting:
  - kdialog (KDE)
  - zenity (GNOME)
  - yad
  - ssh-askpass (fallback)
- `install.sh` installation script with:
  - GUI dialog tool detection
  - Automatic sudoers configuration
  - Configurable timeout (`--timeout` flag)
  - `!tty_tickets` for cross-terminal credential sharing
- `uninstall.sh` clean removal script
- `install-remote.sh` one-liner installation support
- Comprehensive documentation:
  - README.md with usage examples
  - TROUBLESHOOTING.md for common issues
  - SECURITY.md explaining credential caching
  - ARCHITECTURE.md for developers/AI
  - CONTRIBUTING.md guidelines
- `llms.txt` AI documentation index
- MIT License

### Security
- No password storage - uses sudo timestamp files only
- No NOPASSWD entries - requires authentication each session
- Full audit trail preserved in system logs
- Configurable credential timeout (default 90 minutes)

---

## Version History

| Version | Date | Summary |
|---------|------|---------|
| 1.0.2 | 2025-12-21 | Fix SIGKILL edge case, add documentation |
| 1.0.1 | 2025-12-20 | Critical bugfix: prevent keepalive orphaning |
| 1.0.0 | 2025-12-19 | Initial release |

---

## Upgrade Notes

### From 1.0.0 to 1.0.1

**IMPORTANT:** This update fixes a critical bug where keepalive processes were orphaned.

1. Uninstall the old version (this will also kill orphaned processes):
   ```bash
   cd claude-sudo-tools
   git pull origin main
   ./scripts/uninstall.sh
   ```

2. Reinstall:
   ```bash
   ./scripts/install.sh
   ```

If you're upgrading from 1.0.0, you likely have orphaned processes. The uninstaller will clean these up automatically.

### From pre-release to 1.0.0

If you installed from an earlier version:

1. Run uninstaller:
   ```bash
   ./scripts/uninstall.sh
   ```

2. Pull latest:
   ```bash
   git pull origin main
   ```

3. Re-install:
   ```bash
   ./scripts/install.sh
   ```

The main change is the addition of `!tty_tickets` in sudoers config, which fixes the "password prompt on every command" issue.
