#!/usr/bin/env bash
# Caelestia Fedora installer — main setup runner.
# Mirrors the caelestia-kde layout: numbered steps in scripts/, shared libs in scripts/lib/.
set -euo pipefail
export CAELESTIA_SETUP_RUNNING=1

tput civis 2>/dev/null || true
cleanup() {
    tput cnorm 2>/dev/null || true
    caelestia_stop_sudo_keepalive 2>/dev/null || true
}
trap cleanup EXIT

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

# Steps run as separate bash processes, so everything they read from the
# environment has to be exported here.
export DRY_RUN ASSUME_YES CAELESTIA_VM CONFIG_DIR

run_step() {
    local step="$1"; shift
    # The preflight step is read-only apart from guarded package installs, so
    # it still runs in dry-run mode; everything else would change the system.
    if [[ "${DRY_RUN}" == "1" && "${step}" != "01-ensure-prereqs" ]]; then
        dry "step ${step}${*+: $*}"
        return 0
    fi
    bash "${SCRIPTS_DIR}/${step}.sh" "$@"
}

# Choose the optional components (step 16). CAELESTIA_OPTIONAL_APPS="a b"
# overrides the menu; otherwise gum presents a multi-select on a terminal.
select_optional_apps() {
    OPTIONAL_APPS=()
    local -a apps=(starship firefox nvim zed vscode vscodium discord spotify todoist uwsm)

    if [[ -n "${CAELESTIA_OPTIONAL_APPS:-}" ]]; then
        read -r -a OPTIONAL_APPS <<<"${CAELESTIA_OPTIONAL_APPS}"
        return 0
    fi
    if [[ "${ASSUME_YES}" == "1" || "${DRY_RUN}" == "1" ]] \
        || [[ ! -t 0 ]] || ! have_cmd gum; then
        return 0
    fi

    local picked line
    picked="$(gum choose --no-limit --height 12 \
        --header "Optional apps (space selects, enter confirms)" \
        "${apps[@]}" 2>/dev/null || true)"
    while IFS= read -r line; do
        [[ -n "${line}" ]] && OPTIONAL_APPS+=("${line}")
    done <<<"${picked}"
    return 0
}

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -y, --yes        non-interactive; accept all prompts
  -n, --dry-run    print what would happen without changing the system
      --vm         force virtual-machine software-rendering fixes
  -h, --help       show this help

Environment:
  CAELESTIA_REF, CAELESTIA_DIR, CAELESTIA_BRANCH, CAELESTIA_REPO,
  CAELESTIA_OPTIONAL_APPS, DRY_RUN, ASSUME_YES, CAELESTIA_VM
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)     ASSUME_YES=1 ;;
            -n|--dry-run) DRY_RUN=1 ;;
            --vm)         CAELESTIA_VM=1 ;;
            -h|--help)    usage; exit 0 ;;
            *)            die "Unknown option: $1 (try --help)" ;;
        esac
        shift
    done
    export DRY_RUN ASSUME_YES CAELESTIA_VM
}

# ---------------------------------------------------------------------------
# Step runner
# ---------------------------------------------------------------------------
main() {
    section() { printf '\n  == %s ==\n' "$1"; }

    warn "Existing Hyprland configuration will be backed up before being replaced."
    confirm "Proceed with the installation?" || { info "aborted"; exit 0; }

    select_optional_apps

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
        if [[ "${step}" == "16-optional-apps" ]]; then
            run_step "${step}" "${OPTIONAL_APPS[@]}"
        else
            run_step "${step}"
        fi
    done

    ok "Caelestia installation complete"
    printf '\n'
    printf '  Next steps:\n'
    printf '    1. Log out, then select "Hyprland (Caelestia)" at the login screen.\n'
    printf '    2. Super+Super opens the launcher; Super+Tab opens the nexus.\n'
    printf '    3. Put wallpapers in ~/Pictures/Wallpapers and pick one from the shell.\n'
    printf '\n'
}

parse_args "$@"
main "$@"
