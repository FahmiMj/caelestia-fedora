#!/usr/bin/env bash
# shellcheck shell=bash
#
# Shared helpers for the Caelestia Fedora installer.
# Sourced by install.sh and by every setup/*.sh module.

set -euo pipefail

# ---------------------------------------------------------------------------
# Tunables (override via environment)
# ---------------------------------------------------------------------------
: "${CAELESTIA_SHELL_REPO:=https://github.com/caelestia-dots/shell.git}"
: "${CAELESTIA_CLI_REPO:=https://github.com/caelestia-dots/cli.git}"
: "${CAELESTIA_DOTS_REPO:=https://github.com/caelestia-dots/caelestia.git}"
: "${CAVA_REPO:=https://github.com/LukashonakV/cava.git}"
: "${M3SHAPES_REPO:=https://github.com/soramanew/m3shapes.git}"
: "${CAELESTIA_REF:=main}"

: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME

CAELESTIA_STATE="${XDG_CACHE_HOME}/caelestia-fedora"
CAELESTIA_SRC="${CAELESTIA_STATE}/src"
CAELESTIA_LOG="${CAELESTIA_STATE}/install.log"
export CAELESTIA_STATE CAELESTIA_SRC CAELESTIA_LOG

DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"

# Root of this repository (directory that contains install.sh).
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export REPO_DIR
# shellcheck disable=SC2034  # used by the setup/*.sh modules
CONFIG_DIR="${REPO_DIR}/config"

# ---------------------------------------------------------------------------
# Pretty output
# ---------------------------------------------------------------------------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
    C_RESET="$(tput sgr0)";  C_BOLD="$(tput bold)"
    C_RED="$(tput setaf 1)"; C_GREEN="$(tput setaf 2)"; C_YELLOW="$(tput setaf 3)"
    C_BLUE="$(tput setaf 4)"; C_MAGENTA="$(tput setaf 5)"; C_CYAN="$(tput setaf 6)"
else
    C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_MAGENTA=""; C_CYAN=""
fi

log()     { printf '%b\n' "${C_BLUE}${C_BOLD}[caelestia]${C_RESET} $*"; }
info()    { printf '%b\n' "  ${C_CYAN}->${C_RESET} $*"; }
ok()      { printf '%b\n' "  ${C_GREEN}✓${C_RESET} $*"; }
warn()    { printf '%b\n' "  ${C_YELLOW}!${C_RESET} $*" >&2; }
err()     { printf '%b\n' "  ${C_RED}✗${C_RESET} $*" >&2; }
die()     { err "$*"; exit 1; }
section() { printf '\n%b\n' "${C_MAGENTA}${C_BOLD}== $* ==${C_RESET}"; }
dry()     { printf '%b\n' "  ${C_YELLOW}[dry-run]${C_RESET} $*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Command execution
# ---------------------------------------------------------------------------
SUDO=()
if [[ "${EUID}" -ne 0 ]]; then
    if have_cmd sudo; then
        SUDO=(sudo)
    else
        die "sudo is required to install system packages"
    fi
fi

run() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        dry "$*"
        return 0
    fi
    "$@"
}

srun() { run "${SUDO[@]}" "$@"; }

# ---------------------------------------------------------------------------
# Prompting
# ---------------------------------------------------------------------------
confirm() {
    local prompt="${1:-Continue?}"
    if [[ "${ASSUME_YES}" == "1" ]]; then
        return 0
    fi
    if have_cmd gum; then
        gum confirm "$prompt"
    else
        local reply
        read -r -p "${prompt} [y/N] " reply
        [[ "${reply}" =~ ^[Yy]$ ]]
    fi
}

# ---------------------------------------------------------------------------
# Package helpers
# ---------------------------------------------------------------------------
pkg_installed() { rpm -q "$1" >/dev/null 2>&1; }

pkg_available() {
    pkg_installed "$1" && return 0
    dnf -q list --available "$1" >/dev/null 2>&1
}

# Install only the packages that are present in the enabled repositories.
dnf_install() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        dry "dnf install -y --skip-unavailable $*"
        return 0
    fi
    local pkg
    local -a want=()
    for pkg in "$@"; do
        if pkg_installed "${pkg}"; then
            info "already installed: ${pkg}"
            continue
        fi
        if pkg_available "${pkg}"; then
            want+=("${pkg}")
        else
            warn "not available in enabled repos, skipping: ${pkg}"
        fi
    done
    if [[ ${#want[@]} -eq 0 ]]; then
        ok "nothing to install"
        return 0
    fi
    info "dnf install: ${want[*]}"
    srun dnf install -y --skip-unavailable "${want[@]}"
}

copr_enable() {
    local copr="$1"
    local owner="${copr%%/*}" name="${copr##*/}"
    local repo="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${owner}:${name}.repo"
    if [[ -f "${repo}" ]]; then
        info "COPR already enabled: ${copr}"
        return 0
    fi
    info "enabling COPR: ${copr}"
    srun dnf copr enable -y "${copr}"
}

rpmfusion_enable() {
    local rel repo
    rel="$(rpm -E %fedora)"
    repo="/etc/yum.repos.d/rpmfusion-free.repo"
    if [[ ! -f "${repo}" ]]; then
        info "enabling RPM Fusion (free)"
        srun dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${rel}.noarch.rpm"
    else
        info "RPM Fusion (free) already enabled"
    fi
    repo="/etc/yum.repos.d/rpmfusion-nonfree.repo"
    if [[ ! -f "${repo}" ]]; then
        info "enabling RPM Fusion (nonfree)"
        srun dnf install -y \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${rel}.noarch.rpm"
    else
        info "RPM Fusion (nonfree) already enabled"
    fi
}

# ---------------------------------------------------------------------------
# Filesystem helpers
# ---------------------------------------------------------------------------
git_sync() {
    local repo="$1" dest="$2" ref="${3:-}"
    if [[ -d "${dest}/.git" ]]; then
        info "updating $(basename "${dest}")"
        run git -C "${dest}" fetch --depth=1 origin
        if [[ -n "${ref}" ]]; then
            run git -C "${dest}" fetch --depth=1 origin "${ref}"
            run git -C "${dest}" checkout --force FETCH_HEAD
        else
            run git -C "${dest}" reset --hard origin/HEAD
        fi
    else
        run rm -rf "${dest}"
        if [[ -n "${ref}" ]]; then
            run git clone --depth=1 --branch "${ref}" "${repo}" "${dest}"
        else
            run git clone --depth=1 "${repo}" "${dest}"
        fi
    fi
}

backup_path() {
    local path="$1" bak
    [[ -e "${path}" || -L "${path}" ]] || return 0
    bak="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    warn "backing up ${path} -> ${bak}"
    run mv "${path}" "${bak}"
}

install_root_file() {
    local src="$1" dest="$2" mode="${3:-0644}"
    srun install -Dm"${mode}" "${src}" "${dest}"
}

ensure_dir() { run mkdir -p "$@"; }

write_if_absent() {
    local src="$1" dest="$2"
    if [[ -e "${dest}" ]]; then
        info "keeping existing ${dest}"
        return 0
    fi
    ensure_dir "$(dirname "${dest}")"
    run cp "${src}" "${dest}"
}
