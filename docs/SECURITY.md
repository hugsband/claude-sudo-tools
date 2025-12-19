# Security

Security model and considerations for claude-sudo-tools.

## Table of Contents

- [Overview](#overview)
- [How Credential Caching Works](#how-credential-caching-works)
- [Comparison to NOPASSWD](#comparison-to-nopasswd)
- [The tty_tickets Tradeoff](#the-tty_tickets-tradeoff)
- [Threat Model](#threat-model)
- [Audit Trail](#audit-trail)
- [Recommendations](#recommendations)

---

## Overview

claude-sudo-tools uses **sudo's built-in credential caching** - it does NOT:
- Store your password anywhere
- Create NOPASSWD entries
- Bypass authentication

You must authenticate with your password each session. The tool simply provides a GUI method for that authentication since Claude Code lacks a TTY.

---

## How Credential Caching Works

### What Actually Happens

1. **You enter password** → sudo verifies against `/etc/shadow`
2. **Password verified** → sudo creates a timestamp file
3. **Subsequent sudo calls** → sudo checks timestamp, not password

### Timestamp Files

Sudo stores timestamps, not credentials:

```bash
# View your timestamp file
sudo ls -la /run/sudo/ts/$USER
```

The file contains:
- User ID
- Session ID
- Timestamp of last authentication
- NO password data

### Cache Duration

Default: 90 minutes (configurable via `--timeout` flag)

After timeout expires:
- Timestamp becomes stale
- Next sudo command requires re-authentication
- GUI prompt appears automatically (SUDO_ASKPASS)

---

## Comparison to NOPASSWD

### NOPASSWD (Dangerous)

```
# /etc/sudoers - DO NOT DO THIS
user ALL=(ALL) NOPASSWD: ALL
```

**Problems:**
- Any process running as your user can sudo without authentication
- Malware can immediately escalate to root
- No authentication barrier whatsoever
- Persists forever until removed

### claude-sudo-tools (Safe)

```
# /etc/sudoers.d/claude-sudo - What we do
Defaults:user timestamp_timeout=90, !tty_tickets
```

**Benefits:**
- Requires password authentication each session
- Credentials expire after 90 minutes
- Only affects credential caching behavior, not authentication
- Can be removed cleanly

---

## The tty_tickets Tradeoff

### What is tty_tickets?

By default, sudo caches credentials **per-terminal**. Each terminal session has its own credential cache.

### Why We Disable It

Claude Code runs commands in various pseudo-terminals. With `tty_tickets` enabled, each command appears to be from a new terminal, requiring re-authentication.

`!tty_tickets` shares credentials across all terminals for your user.

### Security Implication

With `!tty_tickets`:
- If you sudo in Terminal A, Terminal B also has sudo access
- Any process running as your user can use cached credentials

**Mitigation:**
- Credentials still expire (90 min default)
- You still must authenticate initially
- For single-user workstations, this is acceptable
- For shared machines, consider shorter timeouts

### Recommendation by Environment

| Environment | tty_tickets | Timeout | Notes |
|-------------|-------------|---------|-------|
| Personal workstation | Disable (`!tty_tickets`) | 90 min | Default, good balance |
| Shared workstation | Disable (required for Claude) | 15-30 min | Shorter timeout |
| Server/SSH | Keep enabled | Default | Don't use claude-sudo |

---

## Threat Model

### What claude-sudo-tools Protects Against

✅ **Accidental sudo without password** - Still requires initial auth
✅ **Permanent privilege escalation** - Credentials expire
✅ **Password storage** - No passwords stored anywhere
✅ **Audit evasion** - All sudo usage logged

### What It Does NOT Protect Against

❌ **Malicious processes during active session** - If credentials are cached and a malicious process runs as your user, it can sudo
❌ **Physical access** - If someone accesses your unlocked session
❌ **Keyloggers** - Password can be captured during GUI entry

### Risk Assessment

| Scenario | Risk Level | Notes |
|----------|------------|-------|
| Personal laptop, single user | Low | Acceptable for most users |
| Shared workstation | Medium | Use shorter timeout |
| Remote server | High | Don't use, keep tty_tickets |
| Untrusted software running | Medium-High | Any cached creds accessible |

---

## Audit Trail

All sudo usage is logged regardless of credential caching.

### View Sudo Logs

```bash
# Fedora/RHEL (journald)
sudo journalctl -u sudo

# Debian/Ubuntu (syslog)
sudo grep sudo /var/log/auth.log

# All systems
sudo cat /var/log/secure  # if exists
```

### What's Logged

Each sudo invocation logs:
- Timestamp
- Username
- Command executed
- Working directory
- Success/failure

Example:
```
Dec 19 14:30:15 hostname sudo: user : TTY=pts/0 ; PWD=/home/user ; USER=root ; COMMAND=/usr/bin/dnf install htop
```

---

## Recommendations

### For Personal Workstations

Default settings are appropriate:
- 90-minute timeout
- `!tty_tickets` enabled
- Authenticate once per session

### For Shared Machines

1. **Reduce timeout:**
   ```bash
   ./scripts/install.sh --timeout 15
   ```

2. **Lock screen when away** - Cached credentials are session-bound

3. **Consider per-user installation** - Each user has own sudoers entry

### For High-Security Environments

Consider alternatives:
- Don't use claude-sudo-tools
- Use Claude without sudo access
- Implement specific NOPASSWD rules for safe commands only:
  ```
  user ALL=(ALL) NOPASSWD: /usr/bin/dnf, /usr/bin/systemctl status *
  ```

### General Best Practices

1. **Keep system updated** - Patch sudo vulnerabilities promptly
2. **Use strong password** - GUI prompt doesn't prevent brute force
3. **Monitor sudo logs** - Review periodically for anomalies
4. **Lock screen** - Prevents credential abuse when away
5. **Short timeout on shared systems** - 15-30 minutes max

---

## Verifying Security Settings

### Check Current Configuration

```bash
# View sudoers entry
sudo cat /etc/sudoers.d/claude-sudo

# Check timestamp timeout
sudo -l | grep timestamp

# View timestamp file
sudo ls -la /run/sudo/ts/
```

### Invalidate Credentials Manually

```bash
# Invalidate your credentials
sudo -k

# Invalidate ALL credentials (all users)
sudo -K
```

### Test Authentication

```bash
# Force re-authentication
sudo -k
sudo whoami  # Should prompt for password
```

---

## Questions?

If you have security concerns or questions:
- Open an issue: [GitHub Issues](https://github.com/hugsband/claude-sudo-tools/issues)
- Review the source: All code is in `bin/` directory
