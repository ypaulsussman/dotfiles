#!/bin/bash
# Opens the four windows wanted on every login, then places each one on its
# assigned half-monitor. Invoked by autostart/startup-windows.desktop, which
# GNOME reads from ~/.config/autostart/.
#
# Each app is backgrounded: gnome-control-center and gnome-system-monitor stay in
# the foreground until closed, so without `&` the script would block and the
# later windows would never open.

# Autostart runs before GNOME Shell has finished coming up. The .desktop file
# already delays us by 5s; the sleeps below keep the four windows from racing
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
#   eDP-1     1920x1080 at +2520+722  laptop panel, unused here
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

have_wmctrl=1
if ! command -v wmctrl >/dev/null; then
    have_wmctrl=0
    echo "WARNING: wmctrl not installed — windows will open unplaced."
    echo "         Fix with: sudo apt install -y wmctrl"
fi

# Window IDs whose WM_CLASS matches a regex. `wmctrl -lx` column 3 is the class,
# e.g. gnome-terminal-server.Gnome-terminal, org.gnome.Nautilus.org.gnome.Nautilus.
ids_matching() { wmctrl -lx 2>/dev/null | awk -v re="$1" '$3 ~ re {print $1}'; }

# place <class-regex> <X,Y,W,H> <space-separated ids that existed beforehand>
#
# Waits for a window of that class that wasn't already open, then moves it. The
# before/after diff is what disambiguates our three-tab terminal from every
# other gnome-terminal window — they all share one gnome-terminal-server
# process, so WM_CLASS alone can't tell them apart.
place() {
    [ "$have_wmctrl" = 1 ] || return 0
    local re=$1 geo=$2 before=$3 tries=50 id

    while [ "$tries" -gt 0 ]; do
        for id in $(ids_matching "$re"); do
            case " $before " in *" $id "*) continue ;; esac
            wmctrl -i -r "$id" -b remove,maximized_vert,maximized_horz
            wmctrl -i -r "$id" -e "0,$geo"
            echo "placed /$re/ ($id) at $geo"
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
        return 0
    fi

    echo "WARNING: no window matched /$re/ within 10s; left unplaced"
    return 1
}

# 1. Dev services: talon / wtp / hanzi-expand as three tabs in one window.
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

echo "=== launched, exit 0 ==="
