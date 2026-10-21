#!/bin/bash
# Opens the five windows wanted on every login, then places each one on its
# assigned monitor region. Invoked by autostart/startup-windows.desktop, which
# GNOME reads from ~/.config/autostart/. Four land on the first workspace;
# Claude Desktop goes to the laptop panel of the second, ready for the
# Firefox + VS Code session opened there by hand.
#
# Each app is backgrounded: gnome-control-center and gnome-system-monitor stay in
# the foreground until closed, so without `&` the script would block and the
# later windows would never open.

# Autostart runs before GNOME Shell has finished coming up. The .desktop file
# already delays us by 5s; the sleeps below keep the windows from racing
# each other into the same stacking position.
STAGGER=0.7

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/startup-windows.log"
mkdir -p "$(dirname "$LOG")"
exec >"$LOG" 2>&1
echo "=== startup-windows: $(date -Is) ==="

# ---------------------------------------------------------------------------
# Window placement: "X,Y,W,H" in absolute X11 screen pixels.
#
# Monitor map (from `xrandr --query`):
#   DP-1-0.3  1080x1920 at +0+322     portrait, LEFT external
#   DP-1-0.2  1440x2560 at +1080+0    portrait, RIGHT external, primary
#   eDP-1     1920x1080 at +2520+722  laptop panel; only Claude, on workspace 2
#
# The GNOME top bar reserves the screen's first 32px (`xprop -root
# _NET_WORKAREA`). That only bites into the right monitor, since the left one
# already starts at y=322 — hence the asymmetric Y values below.
#
# Re-run `xrandr --query` and redo this arithmetic if you replug the monitors.
# ---------------------------------------------------------------------------
GEO_SOUND="0,322,1080,960"        # left  monitor, top half
GEO_SYSMON="0,1282,1080,960"      # left  monitor, bottom half
GEO_TERMINAL="1080,32,1440,1264"  # right monitor, top half
GEO_FILES="1080,1296,1440,1264"   # right monitor, bottom half
GEO_CLAUDE="2520,722,1920,1080"   # laptop panel, full (top bar isn't on it)

# Claude goes to the second workspace (wmctrl counts from 0). This relies on
# GNOME's dynamic workspaces, which always keep one empty workspace after the
# last occupied one: once the first four windows are up, index 1 exists and is
# empty. `workspaces-only-on-primary` is false here, so that workspace spans
# all three monitors, not just the primary.
CLAUDE_WORKSPACE=1

have_wmctrl=1
if ! command -v wmctrl >/dev/null; then
    have_wmctrl=0
    echo "WARNING: wmctrl not installed — windows will open unplaced."
    echo "         Fix with: sudo apt install -y wmctrl"
fi

# Window IDs whose WM_CLASS matches a regex. `wmctrl -lx` column 3 is the class,
# e.g. gnome-terminal-server.Gnome-terminal, org.gnome.Nautilus.org.gnome.Nautilus.
ids_matching() { wmctrl -lx 2>/dev/null | awk -v re="$1" '$3 ~ re {print $1}'; }

# place <class-regex> <X,Y,W,H> <space-separated ids that existed beforehand> [tries]
#
# Waits (tries x 0.2s, default 10s) for a window of that class that wasn't
# already open, then moves it and leaves its ID in PLACED_ID. The
# before/after diff is what disambiguates our three-tab terminal from every
# other gnome-terminal window — they all share one gnome-terminal-server
# process, so WM_CLASS alone can't tell them apart.
place() {
    PLACED_ID=
    [ "$have_wmctrl" = 1 ] || return 0
    local re=$1 geo=$2 before=$3 tries=${4:-50} id

    while [ "$tries" -gt 0 ]; do
        for id in $(ids_matching "$re"); do
            case " $before " in *" $id "*) continue ;; esac
            wmctrl -i -r "$id" -b remove,maximized_vert,maximized_horz
            wmctrl -i -r "$id" -e "0,$geo"
            echo "placed /$re/ ($id) at $geo"
            PLACED_ID=$id
            return 0
        done
        sleep 0.2
        tries=$((tries - 1))
    done

    # Nautilus, Settings, and System Monitor are single-instance: if one was
    # already running, launching it raises the existing window rather than
    # making a new one. Never hit at login; hit constantly when hand-testing.
    id=$(ids_matching "$re" | tail -1)
    if [ -n "$id" ]; then
        wmctrl -i -r "$id" -b remove,maximized_vert,maximized_horz
        wmctrl -i -r "$id" -e "0,$geo"
        echo "placed /$re/ ($id) at $geo — reused a window that was already open"
        PLACED_ID=$id
        return 0
    fi

    echo "WARNING: no window matched /$re/ within $(( ${4:-50} / 5 ))s; left unplaced"
    return 1
}

# 1. Dev services: talon / wtp as two tabs in one window.
#    `bash -ic` sources ~/.bashrc, which is where startupservices and the
#    aliases it calls are defined. (It logs a harmless "no job control in this
#    shell" warning because stdin here isn't a terminal.)
before=$(ids_matching '[Gg]nome-terminal' | tr '\n' ' ')
bash -ic 'startupservices' </dev/null
place '[Gg]nome-terminal' "$GEO_TERMINAL" "$before"
sleep "$STAGGER"

# 2. Files, at ~/Desktop
before=$(ids_matching '[Nn]autilus' | tr '\n' ' ')
nautilus --new-window "$HOME/Desktop" &
place '[Nn]autilus' "$GEO_FILES" "$before"
sleep "$STAGGER"

# 3. Settings, on the Sound panel
before=$(ids_matching 'gnome-control-center' | tr '\n' ' ')
gnome-control-center sound &
place 'gnome-control-center' "$GEO_SOUND" "$before"
sleep "$STAGGER"

# 4. System Monitor
before=$(ids_matching 'gnome-system-monitor' | tr '\n' ' ')
gnome-system-monitor &
place 'gnome-system-monitor' "$GEO_SYSMON" "$before"
sleep "$STAGGER"

# 5. Claude Desktop, on the laptop panel of the second workspace. Electron is
#    slow to map its first window at login, hence 30s rather than 10s. -t moves
#    the window without switching the view, so you stay on the first workspace.
#    Its output is discarded: it outlives this script and would otherwise keep
#    appending harmless Chromium GL/mojo errors to our log all session.
before=$(ids_matching 'com.anthropic.Claude' | tr '\n' ' ')
claude-desktop >/dev/null 2>&1 &
place 'com.anthropic.Claude' "$GEO_CLAUDE" "$before" 150
if [ -n "$PLACED_ID" ]; then
    wmctrl -i -r "$PLACED_ID" -t "$CLAUDE_WORKSPACE" \
        && echo "moved Claude ($PLACED_ID) to workspace index $CLAUDE_WORKSPACE" \
        || echo "WARNING: couldn't move Claude to workspace index $CLAUDE_WORKSPACE"
fi

echo "=== launched, exit 0 ==="
