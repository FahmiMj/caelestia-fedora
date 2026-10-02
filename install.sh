#!/usr/bin/env bash
#
# Caelestia on Fedora — interactive installer
#
# Usage:
#   ./install.sh                 interactive install
#   ./install.sh --yes           assume "yes" to all prompts (no TUI questions)
#   ./install.sh --dry-run       show what would be done without changing anything
#
# To run this on a machine that does not have the repository yet, use
# ./bootstrap.sh, which clones it and then calls this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}"
export REPO_DIR

if [[ ! -d "${REPO_DIR}/setup" ]]; then
    printf '%s\n' "This must be run from the repository checkout. Use ./bootstrap.sh to fetch it." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
ASSUME_YES=0
DRY_RUN=0

usage() {
    cat <<'EOF'
Caelestia on Fedora — interactive installer

Usage:
  ./install.sh                 interactive install
  ./install.sh --yes           assume "yes" to all prompts (no TUI questions)
  ./install.sh --dry-run       show what would be done without changing anything
  ./install.sh --help          show this help

Environment:
  CAELESTIA_REF           git ref (branch/tag) to install, defaults to "main"

See ./bootstrap.sh for fetching this repository on a fresh machine.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)     ASSUME_YES=1 ;;
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help)    usage; exit 0 ;;
        *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done
export ASSUME_YES DRY_RUN

# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

# ---------------------------------------------------------------------------
# Step runner
# ---------------------------------------------------------------------------
CORE_STEPS=(
    repos
    packages
    build-deps
    shell
    cli
    fonts
    dots
    session
    fedora-fixes
    desktop
    gpu
)

OPTIONAL_APPS=(starship firefox nvim zed vscode vscodium discord spotify todoist uwsm)

run_step() {
    local step="$1"; shift
    if ! bash "${REPO_DIR}/setup/${step}.sh" "$@"; then
        err "step failed: ${step}"
        exit 1
    fi
}

choose_extras() {
    local -a selected=()
    if [[ ! -t 0 || ! -t 1 ]]; then
        warn "no TTY for the optional-app picker; skipping optional apps"
        return 0
    fi
    mapfile -t selected < <(
        gum choose --no-limit \
            --header "Optional apps (space to select, enter to confirm, none is fine)" \
            "${OPTIONAL_APPS[@]}" || true
    )
    if [[ ${#selected[@]} -gt 0 ]]; then
        printf '%s\n' "${selected[@]}"
    fi
}

main() {
    printf '%b\n' "${C_BOLD}${C_MAGENTA}Caelestia on Fedora${C_RESET}"
    printf '%s\n' "Sets up the Caelestia Quickshell desktop on a fresh Fedora system."

    # Preflight is non-interactive and ensures gum + sudo are ready.
    run_step preflight

    if ! have_cmd gum; then
        if [[ "${DRY_RUN}" == "1" ]]; then
            warn "gum not installed (required for the interactive installer)"
        else
            die "gum is required for the interactive installer"
        fi
    fi

    local -a extras=()
    if [[ "${ASSUME_YES}" == "1" || ! -t 0 || ! -t 1 ]]; then
        info "non-interactive mode: installing the standard set"
    else
        local action
        action="$(gum choose \
            --header "What would you like to do?" \
            "Install Caelestia (recommended)" \
            "Install Caelestia + choose optional apps" \
            "Exit")"
        case "${action}" in
            "Install Caelestia + choose optional apps")
                mapfile -t extras < <(choose_extras)
                ;;
            "Install Caelestia (recommended)")
                ;;
            *) info "nothing to do"; exit 0 ;;
        esac
    fi

    warn "Existing Hyprland configuration will be backed up before being replaced."
    confirm "Proceed with the installation?" || { info "aborted"; exit 0; }

    local step
    for step in "${CORE_STEPS[@]}"; do
        run_step "${step}"
    done

    if [[ ${#extras[@]} -gt 0 ]]; then
        run_step extras "${extras[@]}"
    fi

    run_step finish

    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '\n'
        warn "dry run complete — no changes were made"
    fi
}

main "$@"
