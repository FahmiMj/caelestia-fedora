#!/usr/bin/env bash
# Install the GDM/Wayland session entry for Caelestia.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

install_session() {
    section "Login session"
    install_root_file \
        "${CONFIG_DIR}/start-hyprland-caelestia" \
        /usr/local/bin/start-hyprland-caelestia 0755
    install_root_file \
        "${CONFIG_DIR}/wayland-sessions/hyprland-caelestia.desktop" \
        /usr/share/wayland-sessions/hyprland-caelestia.desktop 0644
    ok "session 'Hyprland (Caelestia)' installed"
}

main() { install_session "$@"; }
main "$@"
