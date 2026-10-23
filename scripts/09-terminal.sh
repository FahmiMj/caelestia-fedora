#!/usr/bin/env bash
# Deploy the terminal prompt configuration (oh-my-posh).
# The shell aliases and fastfetch autostart live in config/caelestia/user-config.fish,
# which the dots step installs; here we only place the prompt theme.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"

section() { printf '\n  == %s ==\n' "$1"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

write_if_absent() {
    local src="$1" dest="$2"
    if [[ -e "${dest}" ]]; then
        info "keeping existing ${dest}"
        return 0
    fi
    mkdir -p "$(dirname "${dest}")"
    cp "${src}" "${dest}"
}

main() {
    section "Terminal prompt"
    if ! have_cmd oh-my-posh; then
        warn "oh-my-posh is not installed; the shell will keep the default prompt"
    fi
    write_if_absent "${CONFIG_DIR}/ohmyposh/zen.toml" "${XDG_CONFIG_HOME}/ohmyposh/zen.toml"
    write_if_absent "${CONFIG_DIR}/ohmyposh/colors.json" "${XDG_CONFIG_HOME}/ohmyposh/colors.json"
    ok "oh-my-posh prompt installed"
}

main() { install_terminal "$@"; }
main "$@"
