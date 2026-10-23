#!/usr/bin/env bash
# Install the support tools shipped with this repository.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"

section() { printf '\n  == %s ==\n' "$1"; }

main() {
    section "Support tools"
    local src="${SCRIPT_DIR}/../tools/diag.sh"
    caelestia_sudo install -Dm0755 "${src}" /usr/local/bin/caelestia-diag
    ok "installed caelestia-diag (collects diagnostics for troubleshooting)"
}

main "$@"
