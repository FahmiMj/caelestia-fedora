#!/usr/bin/env bash
# Optional applications. Invoked with the component names to install, e.g.
#   16-optional-apps.sh starship nvim zed
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"
# shellcheck source=scripts/lib/packages.sh
source "${SCRIPT_DIR}/lib/packages.sh"

section() { printf '\n  == %s ==\n' "$1"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

DOTS="${CAELESTIA_SRC}/caelestia"

put_file() {
    local src="$1" dest="$2"
    [[ -f "${src}" ]] || return 0
    mkdir -p "$(dirname "${dest}")"
    cp "${src}" "${dest}"
}

install_starship() {
    have_cmd starship && { ok "starship already installed"; return 0; }
    if [[ "${DRY_RUN}" == "1" ]]; then info "[dry-run] install starship"; return 0; fi
    info "installing starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

install_firefox_theme() {
    have_cmd firefox || { warn "firefox not installed; skipping theme"; return 0; }
    local profile
    for profile in "${HOME}"/.mozilla/firefox/*.default*; do
        [[ -d "${profile}" ]] || continue
        mkdir -p "${profile}/chrome"
        put_file "${DOTS}/firefox/userChrome.css" "${profile}/chrome/userChrome.css"
        put_file "${DOTS}/firefox/user.js" "${profile}/user.js"
        info "firefox theme applied to $(basename "${profile}")"
    done
}

install_nvim() {
    dnf_install neovim
    put_file "${DOTS}/nvim/colors/caelestia.lua" "${XDG_CONFIG_HOME}/nvim/colors/caelestia.lua"
    put_file "${DOTS}/nvim/lua/plugins/caelestia.lua" "${XDG_CONFIG_HOME}/nvim/lua/plugins/caelestia.lua"
}

install_flatpak_hint() {
    warn "'${1}' is not packaged in Fedora's repositories."
    warn "Install it via Flathub: flatpak install flathub ${2}"
}

main() {
    [[ $# -gt 0 ]] || { info "no optional components selected"; return 0; }
    local name
    for name in "$@"; do
        section "Optional: ${name}"
        case "${name}" in
            starship) install_starship ;;
            firefox)  install_firefox_theme ;;
            nvim)     install_nvim ;;
            zed)      install_flatpak_hint zed dev.zed.Zed ;;
            vscode)   install_flatpak_hint vscode com.visualstudio.code ;;
            vscodium) install_flatpak_hint vscodium com.vscodium.codium ;;
            discord)  install_flatpak_hint discord com.discordapp.Discord ;;
            spotify)  install_flatpak_hint spotify com.spotify.Client ;;
            todoist)  install_flatpak_hint todoist com.todoist.Todoist ;;
            uwsm)     dnf_install uwsm ;;
            *)        warn "unknown optional component: ${name}" ;;
        esac
    done
}

main "$@"
