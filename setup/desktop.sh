#!/usr/bin/env bash
# Desktop integration: enable the required systemd services and set sane
# appearance defaults for GTK/GNOME applications.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

enable_services() {
    section "System services"
    if systemctl list-unit-files bluetooth.service >/dev/null 2>&1; then
        srun systemctl enable --now bluetooth.service || warn "could not enable bluetooth.service"
    fi

    if [[ -n "${XDG_RUNTIME_DIR:-}" && -S "${XDG_RUNTIME_DIR}/bus" ]]; then
        run systemctl --user enable --now \
            pipewire.socket pipewire-pulse.socket wireplumber.service \
            || warn "could not enable PipeWire user services (they start on demand)"
    else
        warn "no user D-Bus session; PipeWire services will start on next login"
    fi
}

apply_appearance() {
    section "Appearance defaults"
    have_cmd gsettings || { warn "gsettings unavailable; skipping"; return 0; }
    run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    run gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || true
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    run gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' || true
    run gsettings set org.gnome.desktop.interface cursor-size 24 || true
}

main() {
    enable_services
    apply_appearance
    ok "desktop defaults applied"
}

main "$@"
