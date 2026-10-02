#!/usr/bin/env bash
# Install the fonts Caelestia expects into the user font directory.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

install_fonts() {
    section "Fonts"
    local dest="${XDG_DATA_HOME}/fonts/caelestia"
    ensure_dir "${dest}"
    run cp -f "${CONFIG_DIR}"/fonts/*.ttf "${dest}/"
    if have_cmd fc-cache; then
        run fc-cache -f "${dest}"
    fi
    ok "fonts installed to ${dest}"
}

main() { install_fonts "$@"; }
main "$@"
