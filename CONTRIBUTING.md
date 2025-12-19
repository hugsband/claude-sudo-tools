# Contributing to claude-sudo-tools

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)

---

## Code of Conduct

Be respectful and constructive. We're all here to make useful software.

---

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/hugsband/claude-sudo-tools/issues) first
2. If not found, [open a new issue](https://github.com/hugsband/claude-sudo-tools/issues/new)
3. Include:
   - Your distro and version (e.g., "Fedora 39", "Ubuntu 24.04")
   - Desktop environment (KDE, GNOME, etc.)
   - Output of `claude-sudo --version`
   - Steps to reproduce
   - Expected vs actual behavior
   - Error messages (full text)

### Suggesting Features

1. [Open an issue](https://github.com/hugsband/claude-sudo-tools/issues/new) with `[Feature]` prefix
2. Describe:
   - The use case
   - Proposed solution
   - Alternatives considered

### Submitting Code

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

---

## Development Setup

### Prerequisites

- Bash 4.0+
- shellcheck (for linting)
- A GUI dialog tool (kdialog, zenity, etc.)
- Git

### Clone and Setup

```bash
# Fork on GitHub first, then:
git clone https://github.com/YOUR_USERNAME/claude-sudo-tools.git
cd claude-sudo-tools

# Install shellcheck for linting
sudo dnf install ShellCheck  # Fedora
sudo apt install shellcheck  # Ubuntu

# Make scripts executable
chmod +x bin/* scripts/*
```

### Local Testing

```bash
# Test without installing
export PATH="$PWD/bin:$PATH"
export SUDO_ASKPASS="$PWD/bin/claude-askpass"

# Test askpass directly
./bin/claude-askpass

# Test wrapper (will run actual claude if installed)
./bin/claude-sudo --help
```

---

## Code Style

### Shell Script Guidelines

1. **Use `set -euo pipefail`** at the start of scripts
2. **Quote variables**: `"$variable"` not `$variable`
3. **Use `[[ ]]`** for conditionals, not `[ ]`
4. **Use `$(command)`** for substitution, not backticks
5. **Add comments** for non-obvious logic
6. **Keep functions small** and focused

### Example

```bash
#!/bin/bash
# description - Brief description of script
set -euo pipefail

# Constants
readonly VERSION="1.0.0"
readonly DEFAULT_TIMEOUT=90

# Functions
show_help() {
    cat << 'EOF'
Usage: script [OPTIONS]
EOF
}

# Main logic
main() {
    local arg="${1:-}"

    if [[ "$arg" == "--help" ]]; then
        show_help
        exit 0
    fi
}

main "$@"
```

### Linting

Run shellcheck before committing:

```bash
shellcheck bin/* scripts/*.sh

# Or check specific file
shellcheck bin/claude-sudo
```

Fix all errors. Warnings can be discussed if there's good reason to suppress.

### Formatting

- Use 4 spaces for indentation
- Keep lines under 100 characters
- Use blank lines to separate logical sections
- End files with newline

---

## Pull Request Process

### Before Submitting

1. **Lint your code**: `shellcheck bin/* scripts/*.sh`
2. **Test locally**: Ensure scripts work on your system
3. **Update docs**: If you changed behavior, update relevant docs
4. **Update CHANGELOG**: Add entry under `## [Unreleased]`

### PR Guidelines

1. **Clear title**: Describe what the PR does
2. **Description**: Explain why and how
3. **Small PRs**: Prefer small, focused changes
4. **One feature per PR**: Don't bundle unrelated changes

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
How did you test this?

## Checklist
- [ ] shellcheck passes
- [ ] Tested on my system
- [ ] Updated documentation (if needed)
- [ ] Updated CHANGELOG.md
```

### Review Process

1. Maintainer reviews PR
2. May request changes
3. Once approved, maintainer merges
4. Your contribution is now part of the project!

---

## Testing

### Manual Testing

```bash
# 1. Test installation from clean state
./scripts/uninstall.sh  # Clean up any existing install
./scripts/install.sh

# 2. Test basic functionality
claude-sudo --help
claude-sudo --version

# 3. Test authentication (will prompt)
claude-sudo

# 4. Test uninstall
./scripts/uninstall.sh
```

### Test Matrix

Ideally test on:
- [ ] Fedora/Nobara (KDE)
- [ ] Fedora/Nobara (GNOME)
- [ ] Ubuntu (GNOME)
- [ ] Arch Linux

At minimum, test on your own system.

### Edge Cases to Test

- Running without any dialog tool installed
- Running without claude installed
- Running as root (should fail)
- Invalid arguments
- Cancelling password dialog
- Timeout expiration

---

## Questions?

- Open an issue for questions
- Tag with `[Question]` prefix

Thank you for contributing!
