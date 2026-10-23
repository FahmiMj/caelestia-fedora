#!/usr/bin/env bash
# Caelestia Fedora installer — main setup runner.
# Mirrors the caelestia-kde layout: numbered steps in scripts/, shared libs in scripts/lib/.
set -euo pipefail
export CAELESTIA_SETUP_RUNNING=1

tput civis 2>/dev/null || true

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$BUNDLE_DIR/scripts"
export BUNDLE_DIR
export INSTALL_START_EPOCH="$(date +%s)"

export PATH="$HOME/.local/bin:$PATH"

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/caelestia-setup.lock"
flock -n 9 || { echo "Another Caelestia setup is already running."; exit 1; }

# shellcheck source=scripts/lib/log.sh
source "$SCRIPTS_DIR/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "$SCRIPTS_DIR/lib/privileges.sh"
# shellcheck source=scripts/lib/packages.sh
source "$SCRIPTS_DIR/lib/packages.sh"
# shellcheck source=scripts/lib/install-fs.sh
source "$SCRIPTS_DIR/lib/install-fs.sh"

# Tunables (override via environment)
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
CAELESTIA_VM="${CAELESTIA_VM:-0}"

CONFIG_DIR="${BUNDLE_DIR}/config"

run_step() {
    local step="$1"; shift
    bash "${SCRIPTS_DIR}/${step}.sh" "$@"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

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

backup_path() {
    local path="$1" bak
    [[ -e "${path}" || -L "${path}" ]] || return 0
    bak="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    warn "backing up ${path} -> ${bak}"
    mv "${path}" "${bak}"
}

ensure_dir() { mkdir -p "$@"; }

git_sync() {
    local repo="$1" dest="$2" ref="${3:-}"
    if [[ -d "${dest}/.git" ]]; then
        info "updating $(basename "${dest}")"
        if [[ -f "$(git -C "${dest}" rev-parse --absolute-git-dir)/shallow" ]]; then
            git -C "${dest}" fetch --unshallow --tags origin
        fi
        git -C "${dest}" fetch --tags origin
        if [[ -n "${ref}" ]]; then
            git -C "${dest}" fetch origin "${ref}"
            git -C "${dest}" checkout --force FETCH_HEAD
        else
            git -C "${dest}" reset --hard origin/HEAD
        fi
    else
        rm -rf "${dest}"
        if [[ -n "${ref}" ]]; then
            git clone --branch "${ref}" "${repo}" "${dest}"
        else
            git clone "${repo}" "${dest}"
        fi
    fi
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

# ---------------------------------------------------------------------------
# Step runner
# ---------------------------------------------------------------------------
main() {
    section() { printf '\n  == %s ==\n' "$1"; }

    warn "Existing Hyprland configuration will be backed up before being replaced."
    confirm "Proceed with the installation?" || { info "aborted"; exit 0; }

    local step
    for step in \
        01-ensure-prereqs \
        02-repos \
        03-all-packages \
        04-build-deps \
        05-build-shell \
        06-install-cli \
        07-install-fonts \
        08-deploy-configs \
        09-terminal \
        10-vm-fixes \
        11-install-tools \
        12-install-session \
        13-fedora-fixes \
        14-desktop \
        15-gpu \
        16-optional-apps \
        17-finish; do
        run_step "${step}"
    done

    ok "Caelestia installation complete"
    printf '\n'
    printf '  Next steps:\n'
    printf '    1. Log out, then select "Hyprland (Caelestia)" at the login screen.\n'
    printf '    2. Super+Super opens the launcher; Super+Tab opens the nexus.\n'
    printf '    3. Put wallpapers in ~/Pictures/Wallpapers and pick one from the shell.\n'
    printf '\n'
}

main "$@"
