#!/usr/bin/env bash
# Enable the third-party repositories Caelestia needs on Fedora.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"
# shellcheck source=scripts/lib/packages.sh
source "${SCRIPT_DIR}/lib/packages.sh"

section() { printf '\n  == %s ==\n' "$1"; }

main() {
    section "Repositories"
    dnf_install dnf-plugins-core
    rpmfusion_enable

    # Quickshell + the wider Hyprland stack.
    copr_enable lionheartp/Hyprland
    # Bibata cursors.
    copr_enable peterwu/rendezvous
    # nwg-look / nwg-displays (GUI configuration helpers).
    copr_enable tofik/nwg-shell

    info "refreshing metadata"
    caelestia_sudo dnf makecache -y
    ok "repositories ready"
}

main "$@"
