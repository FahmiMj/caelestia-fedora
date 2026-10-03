#!/usr/bin/env bash
#
# Fresh-install bootstrap for the Caelestia Fedora installer.
#
# Usage (replace <user> with your GitHub account):
#   bash <(curl -fsSL https://raw.githubusercontent.com/<user>/caelestia-fedora/main/bootstrap.sh)
#
# Pass installer flags through, e.g.:
#   bash <(curl -fsSL .../bootstrap.sh) --yes
#
# If the default repository URL below is not set, provide it via the
# CAELESTIA_FEDORA_REPO environment variable or the --repo flag:
#   CAELESTIA_FEDORA_REPO=https://github.com/<user>/caelestia-fedora.git \
#     bash <(curl -fsSL .../bootstrap.sh)
set -euo pipefail

# --- Default repository URL -------------------------------------------------
# The repository is private, so the git credential helper from `gh auth login`
# (or a personal access token) must be configured before this can clone it.
DEFAULT_REPO_URL="${CAELESTIA_FEDORA_REPO:-https://github.com/FahmiMj/caelestia-fedora.git}"
# ----------------------------------------------------------------------------

REF="${CAELESTIA_REF:-main}"
STATE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/caelestia-fedora"
REPO_DIR="${STATE_DIR}/repo"

die()  { printf 'bootstrap: %s\n' "$*" >&2; exit 1; }
info() { printf 'bootstrap: %s\n' "$*"; }

ensure_cmd() {
    command -v "$1" >/dev/null 2>&1 && return 0
    info "installing $2"
    command -v dnf >/dev/null 2>&1 || die "$2 is required and dnf is unavailable"
    sudo dnf install -y "$2"
}

repo_url="${DEFAULT_REPO_URL}"
args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)   repo_url="${2:-}"; shift 2 ;;
        --repo=*) repo_url="${1#*=}"; shift ;;
        --ref)    REF="${2:-}"; shift 2 ;;
        --ref=*)  REF="${1#*=}"; shift ;;
        *)        args+=("$1"); shift ;;
    esac
done

[[ -n "${repo_url}" ]] || die "no repository URL given. Set CAELESTIA_FEDORA_REPO or pass --repo <url>."

ensure_cmd git git
ensure_cmd curl curl

mkdir -p "${STATE_DIR}"
if [[ -d "${REPO_DIR}/.git" ]]; then
    info "updating existing checkout in ${REPO_DIR}"
    git -C "${REPO_DIR}" fetch --depth=1 origin "${REF}"
    git -C "${REPO_DIR}" checkout --force FETCH_HEAD
else
    rm -rf "${REPO_DIR}"
    info "cloning ${repo_url} (${REF})"
    if ! git clone --depth=1 --branch "${REF}" "${repo_url}" "${REPO_DIR}" 2>/dev/null; then
        rm -rf "${REPO_DIR}"
        info "branch/tag '${REF}' not found; cloning the default branch"
        git clone --depth=1 "${repo_url}" "${REPO_DIR}"
    fi
fi

export CAELESTIA_FEDORA_REPO="${repo_url}"
export CAELESTIA_REF="${REF}"

info "starting the installer"
exec bash "${REPO_DIR}/install.sh" "${args[@]}"
