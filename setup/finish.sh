#!/usr/bin/env bash
# Final touches and summary.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

finish() {
    section "Finalising"
    if have_cmd caelestia; then
        if [[ ! -f "${XDG_STATE_HOME}/caelestia/scheme.json" ]]; then
            info "generating initial colour scheme"
            run caelestia scheme set -n caelestia \
                || warn "could not generate the initial scheme; it will be created on first login"
        fi
    else
        warn "caelestia is not on PATH yet; open a new shell and run: caelestia scheme set -n caelestia"
    fi

    ok "Caelestia installation complete"
    printf '\n'
    printf '%b\n' "${C_BOLD}Next steps${C_RESET}"
    printf '  1. Log out, then select %b"Hyprland (Caelestia)"%b at the login screen.\n' \
        "${C_CYAN}" "${C_RESET}"
    printf '  2. Super+Super opens the launcher; Super+Tab opens the nexus.\n'
    printf '  3. Put wallpapers in ~/Pictures/Wallpapers and pick one from the shell.\n'
    printf '\n'
}

main() { finish "$@"; }
main "$@"
