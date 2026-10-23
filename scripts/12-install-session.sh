#!/usr/bin/env bash
# Install the GDM/Wayland session entry for Caelestia.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"

section() { printf '\n  == %s ==\n' "$1"; }

install_session() {
    section "Login session"
    local src="${SCRIPT_DIR}/../config/start-hyprland-caelestia"
    local desktop="${SCRIPT_DIR}/../config/wayland-sessions/hyprland-caelestia.desktop"
    caelestia_sudo install -Dm0755 "${src}" /usr/local/bin/start-hyprland-caelestia
    caelestia_sudo install -Dm0644 "${desktop}" /usr/share/wayland-sessions/hyprland-caelestia.desktop
    ok "session 'Hyprland (Caelestia)' installed"
}

main() { install_session "$@"; }
main "$@"
