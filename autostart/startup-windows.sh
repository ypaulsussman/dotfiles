#!/bin/bash
# Opens the five windows wanted on every login. Invoked by
# autostart/startup-windows.desktop, which the session reads from
# ~/.config/autostart/.
#
# Launch only, no placement. Ubuntu 26.04 / GNOME 50 is Wayland-only, and on
# Wayland wmctrl can't see or move native windows, so the old per-monitor
# placement (git history before 2026-11-05) silently did nothing. Claude
# Desktop's move to workspace 2 is now handled by GNOME's Auto Move Windows
# extension instead:
#   org.gnome.shell.extensions.auto-move-windows application-list
#     = ['com.anthropic.Claude.desktop:2']
#
# Each app is backgrounded: gnome-control-center and resources stay in the
# foreground until closed, so without `&` the script would block and the
# later windows would never open.

# Autostart runs before the shell has finished coming up. The .desktop file
# already delays us by 5s; the sleeps keep the windows from racing each other
# into the same stacking position.
STAGGER=0.7

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/startup-windows.log"
mkdir -p "$(dirname "$LOG")"
exec >"$LOG" 2>&1
echo "=== startup-windows: $(date -Is) session=${XDG_SESSION_TYPE:-?} desktop=${XDG_CURRENT_DESKTOP:-?} ==="

# 1. Dev services terminal. `bash -ic` sources ~/.bashrc, where
#    startupservices lives; it adds the talon tab only in an X11 session
#    (Talon crashes under Wayland). Logs a harmless "no job control" warning.
bash -ic 'startupservices' </dev/null
sleep "$STAGGER"

# 2. Files, at ~/Desktop
nautilus --new-window "$HOME/Desktop" &
sleep "$STAGGER"

# 3. Settings, on the Sound panel
gnome-control-center sound &
sleep "$STAGGER"

# 4. Resources (replaced gnome-system-monitor in Ubuntu 26.04)
resources &
sleep "$STAGGER"

# 5. Claude Desktop. Output discarded: it outlives this script and would
#    otherwise keep appending harmless Chromium GL/mojo errors to our log.
claude-desktop >/dev/null 2>&1 &

echo "=== launched, exit 0 ==="
