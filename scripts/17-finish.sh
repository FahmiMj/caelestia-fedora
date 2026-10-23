#!/usr/bin/env bash
# Final touches and summary.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"

section() { printf '\n  == %s ==\n' "$1"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

main() {
    section "Finalising"
    if have_cmd caelestia; then
        if [[ ! -f "${XDG_STATE_HOME}/caelestia/scheme.json" ]]; then
            info "generating initial colour scheme"
            caelestia scheme set -n caelestia \
                || warn "could not generate the initial scheme; it will be created on first login"
        fi
    else
        warn "caelestia is not on PATH yet; open a new shell and run: caelestia scheme set -n caelestia"
    fi

    ok "Caelestia installation complete"
    printf '\n'
    printf '  Next steps:\n'
    printf '    1. Log out, then select "Hyprland (Caelestia)" at the login screen.\n'
    printf '    2. Super+Super opens the launcher; Super+Tab opens the nexus.\n'
    printf '    3. Put wallpapers in ~/Pictures/Wallpapers and pick one from the shell.\n'
    printf '\n'
}

main "$@"
