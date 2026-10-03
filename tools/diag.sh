#!/usr/bin/env bash
# Collect Caelestia/Hyprland diagnostics. Read-only; prints a report to stdout.
# Usage: bash tools/diag.sh | tee ~/caelestia-diag.txt
set -u

rt="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_RUNTIME_DIR="$rt"

hr() { printf '\n===== %s =====\n' "$1"; }

hr "date"; date
hr "user"; id
hr "loginctl sessions"; loginctl list-sessions --no-legend 2>&1
for s in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
    printf -- '--- session %s ---\n' "$s"
    loginctl show-session "$s" \
        -p Id -p User -p Name -p Type -p Class -p Desktop -p State -p Active -p VTNr 2>&1
done

hr "processes"
pgrep -a -f 'Hyprland|gnome-shell|start-hyprland|quickshell|caelestia' 2>&1 || true

hr "runtime dir"
for f in "$rt"/wayland* "$rt"/hypr "$rt"/quickshell; do
    [ -e "$f" ] && ls -lad "$f"
done

hid="$(find "$rt/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | head -1)"
hr "hypr instances"
printf 'HYPRLAND_INSTANCE_SIGNATURE=%s\n' "${hid:-<none>}"
ls -la "$rt/hypr" 2>&1 || true

hr "hyprctl monitors"
HYPRLAND_INSTANCE_SIGNATURE="$hid" hyprctl monitors 2>&1 | head -20
hr "hyprctl version"
HYPRLAND_INSTANCE_SIGNATURE="$hid" hyprctl version 2>&1 | head -5

hr "Hyprland process env"
for pid in $(pgrep -x Hyprland 2>/dev/null); do
    printf -- '--- pid %s ---\n' "$pid"
    tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
        | grep -E 'WAYLAND_DISPLAY|XDG_|HYPRLAND|QT_QPA|GDK_BACKEND|PATH' || true
done

hr "session wrapper"
cat /usr/local/bin/start-hyprland-caelestia 2>&1 || true

hr "installed session entries"
ls -la /usr/share/wayland-sessions/ 2>&1
printf -- '--- caelestia entry ---\n'
cat /usr/share/wayland-sessions/hyprland-caelestia.desktop 2>&1 || true

hr "quickshell instances"
qs -c caelestia list 2>&1 || true

hr "quickshell logs (newest)"
newest="$(find "$rt/quickshell" -name '*.qslog' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | awk '{print $2}')"
printf 'newest: %s\n' "${newest:-<none>}"
if [ -n "$newest" ]; then tail -80 "$newest"; fi

hr "Hyprland journal"
journalctl -b _COMM=Hyprland --no-pager 2>&1 | tail -60 || true
hr "start-hyprland journal"
journalctl -b _COMM=start-hyprland --no-pager 2>&1 | tail -40 || true

hr "GPU / EGL"
ls -la /dev/dri 2>&1 || true
if command -v eglinfo >/dev/null 2>&1; then eglinfo 2>&1 | head -25; else echo "eglinfo not installed"; fi

hr "done"
