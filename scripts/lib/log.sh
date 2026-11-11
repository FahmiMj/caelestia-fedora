#!/usr/bin/env bash
# Shared logging helpers for the Caelestia Fedora installer.
if [[ -n "${CAELESTIA_LOG_LOADED:-}" ]]; then
    return 0
fi
CAELESTIA_LOG_LOADED=1

info() { printf '  [INFO]  %s\n' "$*"; }
ok()   { printf '  [OK]    %s\n' "$*"; }
warn() { printf '  [WARN]  %s\n' "$*"; }
skip() { printf '  [SKIP]  %s\n' "$*"; }
err()  { printf '  [ERR]   %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

# dry <description>: record a would-be action during --dry-run.
dry() { info "[dry-run] $*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# confirm <prompt>: ask the user, honouring ASSUME_YES=1.
confirm() {
    local prompt="${1:-Continue?}" reply
    if [[ "${ASSUME_YES:-0}" == "1" ]]; then
        return 0
    fi
    if have_cmd gum; then
        gum confirm "$prompt"
        return $?
    fi
    read -r -p "${prompt} [y/N] " reply || return 1
    [[ "${reply}" =~ ^[Yy]([Ee][Ss])?$ ]]
}
