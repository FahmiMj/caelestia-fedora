#!/usr/bin/env bash
# GPU and hardware media acceleration.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

maybe_nvidia() {
    dnf_install pciutils
    if ! lspci 2>/dev/null | grep -qi 'nvidia'; then
        ok "no NVIDIA GPU detected"
        return 0
    fi
    section "NVIDIA GPU detected"
    if lsmod 2>/dev/null | grep -qi '^nvidia'; then
        ok "proprietary NVIDIA driver already loaded"
        return 0
    fi
    warn "An NVIDIA GPU is present but the proprietary driver is not loaded."
    warn "Installing akmod-nvidia can improve performance and enable NVENC, but on"
    warn "systems with Secure Boot it requires enrolling a MOK key (or disabling it)."
    if ! confirm "Install the RPM Fusion NVIDIA driver (akmod-nvidia)?"; then
        info "skipping NVIDIA driver installation"
        return 0
    fi
    dnf_install akmod-nvidia xorg-x11-drv-nvidia-cuda
    ok "NVIDIA driver installed (a reboot is required to load it)"
}

install_gpu() {
    section "GPU / media packages"
    dnf_install \
        libva-utils mesa-va-drivers-freeworld mesa-vulkan-drivers vulkan-loader \
        intel-media-driver gpu-screen-recorder
    maybe_nvidia
    ok "GPU setup complete"
}

main() { install_gpu "$@"; }
main "$@"
