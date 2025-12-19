# Troubleshooting

Common issues and solutions for claude-sudo-tools.

## Table of Contents

- [Password prompt on every command](#password-prompt-on-every-command)
- [No GUI dialog tool found](#no-gui-dialog-tool-found)
- [claude command not found](#claude-command-not-found)
- [Authentication failed or cancelled](#authentication-failed-or-cancelled)
- [Credentials expire mid-session](#credentials-expire-mid-session)
- [Keepalive process issues](#keepalive-process-issues)
- [Permission denied errors](#permission-denied-errors)
- [Uninstall doesn't fully clean up](#uninstall-doesnt-fully-clean-up)
- [GUI dialog doesn't appear](#gui-dialog-doesnt-appear)

---

## Password prompt on every command

**Symptom:** Every `sudo` command triggers a new password dialog, instead of using cached credentials.

**Cause:** By default, sudo uses `tty_tickets` which isolates credentials per-terminal. Claude Code runs commands in different pseudo-terminals, so each command appears to be from a new terminal.

**Solution:**

1. Check if `!tty_tickets` is set:
   ```bash
   sudo cat /etc/sudoers.d/claude-sudo
   ```

2. If missing or wrong, fix it:
   ```bash
   sudo visudo -f /etc/sudoers.d/claude-sudo
   ```

3. Ensure it contains (replace YOUR_USER with your username):
   ```
   Defaults:YOUR_USER timestamp_timeout=90, !tty_tickets
   ```

4. Restart `claude-sudo`

**Note:** The installer should set this automatically. If it didn't, you may have an older installation.

---

## No GUI dialog tool found

**Symptom:** Error message:
```
ERROR: No GUI password dialog available
Install one of: kdialog, zenity, yad, or ssh-askpass
```

**Cause:** No supported GUI dialog tool is installed.

**Solution:**

Install a dialog tool for your desktop environment:

```bash
# KDE (Fedora/Nobara)
sudo dnf install kdialog

# GNOME (Fedora/Nobara)
sudo dnf install zenity

# Ubuntu/Debian
sudo apt install zenity

# Arch Linux
sudo pacman -S zenity

# Universal fallback
sudo dnf install openssh-askpass  # or apt install ssh-askpass
```

**Recommendation:** Use `kdialog` on KDE, `zenity` on GNOME.

---

## claude command not found

**Symptom:** Error or warning about missing `claude` command.

**Cause:** Claude Code CLI is not installed or not in PATH.

**Solution:**

1. Install Claude Code:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. Or if installed but not in PATH, find it:
   ```bash
   which claude
   # or
   npm list -g @anthropic-ai/claude-code
   ```

3. Add to PATH if needed (in `~/.bashrc`):
   ```bash
   export PATH="$PATH:$(npm bin -g)"
   ```

---

## Authentication failed or cancelled

**Symptom:** Message:
```
Authentication failed or cancelled.
```

**Causes:**
1. Wrong password entered
2. Dialog was closed/cancelled
3. Dialog timed out (60 seconds)
4. GUI dialog crashed

**Solutions:**

1. **Wrong password:** Try again, ensure caps lock is off

2. **Dialog cancelled:** Don't click "Cancel" - enter your password

3. **Dialog timed out:** zenity/yad have a 60-second timeout. Enter password promptly.

4. **Dialog crashed:** Check if your GUI environment is working:
   ```bash
   # Test dialog manually
   kdialog --password "Test"
   # or
   zenity --password
   ```

---

## Credentials expire mid-session

**Symptom:** After 90 minutes, sudo commands start failing or prompting again.

**Cause:** The credential timeout expired. The keepalive process should prevent this, but if it died or couldn't refresh, credentials expire.

**What happens:**
- With `SUDO_ASKPASS` set, the next sudo command will trigger a new GUI prompt
- You don't need to restart `claude-sudo`, just authenticate again

**If keepalive isn't working:**

1. Check if keepalive is running:
   ```bash
   ps aux | grep "sudo -A -v"
   ```

2. Check for errors in the wrapper by running with debug:
   ```bash
   bash -x /usr/local/bin/claude-sudo
   ```

3. Verify SUDO_ASKPASS is set:
   ```bash
   echo $SUDO_ASKPASS
   # Should show: /usr/local/bin/claude-askpass
   ```

---

## Keepalive process issues

**Symptom:** Orphan keepalive processes after Claude exits.

**Cause:** Claude was killed forcefully (SIGKILL) or the trap didn't execute.

**Solution:**

1. Find and kill orphan processes:
   ```bash
   # Find keepalive processes
   ps aux | grep "sleep 240"

   # Kill them
   pkill -f "sleep 240"
   ```

2. The wrapper uses `trap` to clean up on normal exit. This handles:
   - EXIT (normal exit)
   - INT (Ctrl+C)
   - TERM (kill command)
   - HUP (terminal closed)

   SIGKILL (kill -9) cannot be trapped, so avoid using it.

---

## Permission denied errors

**Symptom:** Various "permission denied" errors during install or runtime.

**Solutions:**

### During installation

Don't run the installer as root:
```bash
# Wrong
sudo ./scripts/install.sh

# Right
./scripts/install.sh  # It will use sudo internally when needed
```

### During runtime

Check file permissions:
```bash
ls -la /usr/local/bin/claude-sudo
ls -la /usr/local/bin/claude-askpass
# Should be: -rwxr-xr-x (755)

ls -la /etc/sudoers.d/claude-sudo
# Should be: -r--r----- (440)
```

Fix permissions if needed:
```bash
sudo chmod 755 /usr/local/bin/claude-sudo
sudo chmod 755 /usr/local/bin/claude-askpass
sudo chmod 440 /etc/sudoers.d/claude-sudo
```

---

## Uninstall doesn't fully clean up

**Symptom:** After uninstall, some files or settings remain.

**Solution:**

Manual cleanup:
```bash
# Remove binaries
sudo rm -f /usr/local/bin/claude-sudo
sudo rm -f /usr/local/bin/claude-askpass

# Remove sudoers config
sudo rm -f /etc/sudoers.d/claude-sudo

# Kill any running keepalive processes
pkill -f "claude-sudo"

# Invalidate cached sudo credentials
sudo -K
```

---

## GUI dialog doesn't appear

**Symptom:** claude-sudo hangs waiting for password, but no dialog shows.

**Causes:**
1. Running in a non-GUI environment (SSH, TTY)
2. Display environment not set
3. Wayland/X11 issues

**Solutions:**

1. **Check DISPLAY/WAYLAND:**
   ```bash
   echo $DISPLAY
   echo $WAYLAND_DISPLAY
   # At least one should be set
   ```

2. **SSH sessions:** Forward X11:
   ```bash
   ssh -X user@host
   ```

3. **Wayland issues:** Some dialogs need XWayland. Try:
   ```bash
   # Install XWayland support
   sudo dnf install xorg-x11-server-Xwayland
   ```

4. **Test dialog directly:**
   ```bash
   DISPLAY=:0 kdialog --password "Test"
   ```

---

## Getting Help

If your issue isn't listed here:

1. **Check logs:**
   ```bash
   # Sudo auth log
   sudo tail -50 /var/log/auth.log
   # or on Fedora
   sudo journalctl -u sudo
   ```

2. **Run with debug:**
   ```bash
   bash -x /usr/local/bin/claude-sudo
   ```

3. **Open an issue:** [GitHub Issues](https://github.com/hugsband/claude-sudo-tools/issues)

Include:
- Your distro and version
- Desktop environment (KDE, GNOME, etc.)
- Output of `claude-sudo --version`
- Error messages
- Steps to reproduce
