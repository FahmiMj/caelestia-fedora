#!/usr/bin/env bash
# Deploy the Caelestia dotfiles (Hyprland config + default app configs) and the
# Fedora-specific user overrides.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"

section() { printf '\n  == %s ==\n' "$1"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

backup_path() {
    local path="$1" bak
    [[ -e "${path}" || -L "${path}" ]] || return 0
    bak="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    warn "backing up ${path} -> ${bak}"
    mv "${path}" "${bak}"
}

ensure_dir() { mkdir -p "$@"; }

copy_tree() {
    local src="$1" dest="$2"
    if [[ ! -d "${src}" ]]; then
        warn "component source missing, skipping: ${src}"
        return 0
    fi
    backup_path "${dest}"
    ensure_dir "$(dirname "${dest}")"
    cp -rT "${src}" "${dest}"
}

copy_file() {
    local src="$1" dest="$2"
    if [[ ! -f "${src}" ]]; then
        warn "component file missing, skipping: ${src}"
        return 0
    fi
    backup_path "${dest}"
    ensure_dir "$(dirname "${dest}")"
    cp "${src}" "${dest}"
}

write_if_absent() {
    local src="$1" dest="$2"
    if [[ -e "${dest}" ]]; then
        info "keeping existing ${dest}"
        return 0
    fi
    ensure_dir "$(dirname "${dest}")"
    cp "${src}" "${dest}"
}

main() {
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

    # Hyprland variables.lua requires scheme.current; ensure it exists by
    # copying from scheme.default. Without this, every vars.* reference is nil
    # and Hyprland --verify-config fails with cascading errors.
    # See: install logs, BUG 6/7 (scheme/current.lua missing)
    if [[ -f "${dots}/hypr/scheme/default.lua" && ! -f "${dots}/hypr/scheme/current.lua" ]]; then
        cp "${dots}/hypr/scheme/default.lua" "${dots}/hypr/scheme/current.lua"
    fi
    if [[ -f "${XDG_CONFIG_HOME}/hypr/scheme/default.lua" && ! -f "${XDG_CONFIG_HOME}/hypr/scheme/current.lua" ]]; then
        cp "${XDG_CONFIG_HOME}/hypr/scheme/default.lua" "${XDG_CONFIG_HOME}/hypr/scheme/current.lua"
    fi

    # fish component post_install step from the upstream manifest: a personal
    # config that fish/config.fish sources last. Seed it from this repository
    # when it is missing or still empty (earlier installs created it empty).
    ensure_dir "${XDG_CONFIG_HOME}/caelestia"
    local user_config="${XDG_CONFIG_HOME}/caelestia/user-config.fish"
    if [[ ! -s "${user_config}" ]]; then
        cp "${CONFIG_DIR}/caelestia/user-config.fish" "${user_config}"
    else
        info "keeping existing ${user_config}"
    fi

    section "Caelestia user overrides"
    ensure_dir "${XDG_CONFIG_HOME}/caelestia"
    write_if_absent "${CONFIG_DIR}/caelestia/hypr-vars.lua" "${XDG_CONFIG_HOME}/caelestia/hypr-vars.lua"
    write_if_absent "${CONFIG_DIR}/caelestia/hypr-user.lua" "${XDG_CONFIG_HOME}/caelestia/hypr-user.lua"
    write_if_absent "${CONFIG_DIR}/caelestia/shell.json"    "${XDG_CONFIG_HOME}/caelestia/shell.json"
    write_if_absent "${CONFIG_DIR}/caelestia/fastfetch/config.jsonc" "${XDG_CONFIG_HOME}/caelestia-fastfetch/config.jsonc"

    if have_cmd xdg-user-dirs-update; then
        xdg-user-dirs-update
    fi
    ok "dotfiles deployed"
}

main() { install_dots "$@"; }
main "$@"
