#!/usr/bin/env bash
# Install the fonts Caelestia expects into the user font directory.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"

section() { printf '\n  == %s ==\n' "$1"; }

install_fonts() {
    section "Fonts"
    local dest="${XDG_DATA_HOME}/fonts/caelestia"
    ensure_dir "${dest}"
    cp -f "${CONFIG_DIR}"/fonts/*.ttf "${dest}/"
    if have_cmd fc-cache; then
        fc-cache -f "${dest}"
    fi
    ok "fonts installed to ${dest}"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

main() { install_fonts "$@"; }
main "$@"
