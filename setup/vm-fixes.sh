#!/usr/bin/env bash
# Apply extra fixes for running Caelestia inside a virtual machine.
#
# Selected by the "Install Caelestia (VirtualBox)" installer option, which
# exports CAELESTIA_VM=1. VM GPU drivers (VMware vmwgfx, VirtualBox vmsvga)
# mishandle surface-backed dmabufs, so Hyprland disconnects every
# GPU-accelerated Wayland client (the shell included) and the session renders
# as a black screen with only the cursor. Forcing software rendering avoids it
# until the upstream Hyprland fix lands
# (https://github.com/hyprwm/Hyprland/discussions/12966).
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

VM_ENV_BLOCK='

-- Virtual machine software-rendering fallback (added by the Caelestia Fedora
-- installer). hypr-user.lua is required last, so these environment variables
-- are inherited by every process Hyprland launches, including the shell.
-- Remove these two lines to go back to the (buggy) hardware path.
hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
hl.env("QSG_RHI_BACKEND", "software")'

apply_vm_fixes() {
    section "Virtual machine fixes"
    if [[ "${CAELESTIA_VM:-0}" != "1" ]]; then
        info "not a VM install; skipping"
        return 0
    fi

    local target="${XDG_CONFIG_HOME}/caelestia/hypr-user.lua"
    if [[ -f "${target}" ]] && grep -q 'LIBGL_ALWAYS_SOFTWARE' "${target}"; then
        ok "software rendering already configured in ${target}"
        return 0
    fi

    if [[ "${DRY_RUN}" == "1" ]]; then
        dry "append software-rendering hl.env block to ${target}"
        return 0
    fi

    ensure_dir "$(dirname "${target}")"
    printf '%s\n' "${VM_ENV_BLOCK}" >> "${target}"
    ok "software rendering enabled for virtual machines"
}

main() { apply_vm_fixes "$@"; }
main "$@"
