#!/usr/bin/env bash
# Install the support tools shipped with this repository.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

install_tools() {
    section "Support tools"
    install_root_file "${REPO_DIR}/tools/diag.sh" /usr/local/bin/caelestia-diag 0755
    ok "installed caelestia-diag (collects diagnostics for troubleshooting)"
}

main() { install_tools "$@"; }
main "$@"
