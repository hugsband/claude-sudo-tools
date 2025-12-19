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
| 1.0.0 | 2025-12-19 | Initial release |

---

## Upgrade Notes

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
