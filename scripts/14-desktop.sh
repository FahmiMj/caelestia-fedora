#!/usr/bin/env bash
# Desktop integration: enable the required systemd services and set sane
# appearance defaults for GTK/GNOME applications.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"

section() { printf '\n  == %s ==\n' "$1"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

enable_services() {
    section "System services"
    if systemctl list-unit-files bluetooth.service >/dev/null 2>&1; then
        caelestia_sudo systemctl enable --now bluetooth.service || warn "could not enable bluetooth.service"
    fi

    if [[ -n "${XDG_RUNTIME_DIR:-}" && -S "${XDG_RUNTIME_DIR}/bus" ]]; then
        systemctl --user enable --now \
            pipewire.socket pipewire-pulse.socket wireplumber.service \
            || warn "could not enable PipeWire user services (they start on demand)"
    else
        warn "no user D-Bus session; PipeWire services will start on next login"
    fi
}

apply_appearance() {
    section "Appearance defaults"
    have_cmd gsettings || { warn "gsettings unavailable; skipping"; return 0; }
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' || true
    gsettings set org.gnome.desktop.interface cursor-size 24 || true
}

main() {
    enable_services
    apply_appearance
    ok "desktop defaults applied"
}

main "$@"
