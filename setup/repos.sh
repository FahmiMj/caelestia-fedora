#!/usr/bin/env bash
# Enable the third-party repositories Caelestia needs on Fedora.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

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
    srun dnf makecache -y
    ok "repositories ready"
}

main "$@"
