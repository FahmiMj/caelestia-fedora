#!/usr/bin/env bash
# Install the `caelestia` CLI in an isolated pipx environment.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

install_cli() {
    section "Caelestia CLI"
    dnf_install pipx
    run pipx ensurepath

    local dir="${CAELESTIA_SRC}/cli"
    git_sync "${CAELESTIA_CLI_REPO}" "${dir}" "${CAELESTIA_REF}"
    run pipx install --force "${dir}"

    if have_cmd caelestia; then
        ok "caelestia CLI installed: $(caelestia --version 2>/dev/null || echo '?')"
    else
        warn "caelestia is not on PATH in this shell yet; it will be after re-login"
    fi
}

main() { install_cli "$@"; }
main "$@"
