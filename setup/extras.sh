#!/usr/bin/env bash
# Optional applications. Invoked with the component names to install, e.g.
#   extras.sh starship nvim zed
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

DOTS="${CAELESTIA_SRC}/caelestia"

put_file() {
    local src="$1" dest="$2"
    [[ -f "${src}" ]] || return 0
    ensure_dir "$(dirname "${dest}")"
    run cp "${src}" "${dest}"
}

install_starship() {
    have_cmd starship && { ok "starship already installed"; return 0; }
    if [[ "${DRY_RUN}" == "1" ]]; then dry "install starship"; return 0; fi
    info "installing starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

install_firefox_theme() {
    have_cmd firefox || { warn "firefox not installed; skipping theme"; return 0; }
    local profile
    for profile in "${HOME}"/.mozilla/firefox/*.default*; do
        [[ -d "${profile}" ]] || continue
        ensure_dir "${profile}/chrome"
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
