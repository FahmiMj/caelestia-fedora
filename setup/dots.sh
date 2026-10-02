#!/usr/bin/env bash
# Deploy the Caelestia dotfiles (Hyprland config + default app configs) and the
# Fedora-specific user overrides.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

copy_tree() {
    local src="$1" dest="$2"
    if [[ ! -d "${src}" ]]; then
        warn "component source missing, skipping: ${src}"
        return 0
    fi
    backup_path "${dest}"
    ensure_dir "$(dirname "${dest}")"
    run cp -rT "${src}" "${dest}"
}

copy_file() {
    local src="$1" dest="$2"
    if [[ ! -f "${src}" ]]; then
        warn "component file missing, skipping: ${src}"
        return 0
    fi
    backup_path "${dest}"
    ensure_dir "$(dirname "${dest}")"
    run cp "${src}" "${dest}"
}

install_dots() {
    section "Caelestia dotfiles"
    local dots="${CAELESTIA_SRC}/caelestia"
    git_sync "${CAELESTIA_DOTS_REPO}" "${dots}" "${CAELESTIA_REF}"

    local pair src dest
    local -a pairs=(
        "hypr:hypr"
        "fish:fish"
        "foot:foot"
        "fastfetch:fastfetch"
        "btop:btop"
        "micro:micro"
        "thunar:Thunar"
    )
    for pair in "${pairs[@]}"; do
        src="${dots}/${pair%%:*}"
        dest="${XDG_CONFIG_HOME}/${pair##*:}"
        copy_tree "${src}" "${dest}"
    done
    copy_file "${dots}/starship.toml" "${XDG_CONFIG_HOME}/starship.toml"

    # fish component post_install steps from the upstream manifest.
    ensure_dir "${XDG_CONFIG_HOME}/caelestia"
    run touch "${XDG_CONFIG_HOME}/caelestia/user-config.fish"

    section "Caelestia user overrides"
    ensure_dir "${XDG_CONFIG_HOME}/caelestia"
    write_if_absent "${CONFIG_DIR}/caelestia/hypr-vars.lua" "${XDG_CONFIG_HOME}/caelestia/hypr-vars.lua"
    write_if_absent "${CONFIG_DIR}/caelestia/hypr-user.lua" "${XDG_CONFIG_HOME}/caelestia/hypr-user.lua"
    write_if_absent "${CONFIG_DIR}/caelestia/shell.json"    "${XDG_CONFIG_HOME}/caelestia/shell.json"

    if have_cmd xdg-user-dirs-update; then
        run xdg-user-dirs-update
    fi
    ok "dotfiles deployed"
}

main() { install_dots "$@"; }
main "$@"
