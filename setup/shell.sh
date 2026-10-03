#!/usr/bin/env bash
# Install the Caelestia Quickshell config: build the QML plugin/module and place
# the config in ~/.config/quickshell/caelestia.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

install_shell() {
    section "Caelestia shell"
    dnf_install quickshell

    local dir="${XDG_CONFIG_HOME}/quickshell/caelestia"
    ensure_dir "${XDG_CONFIG_HOME}/quickshell"
    git_sync "${CAELESTIA_SHELL_REPO}" "${dir}" "${CAELESTIA_REF}"

    info "configuring (cmake)"
    run cmake -B "${dir}/build" -S "${dir}" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/ \
        -DDISTRIBUTOR=Fedora \
        -DINSTALL_QSCONFDIR="${dir}"
    info "building"
    run cmake --build "${dir}/build"
    info "installing (sudo)"
    srun cmake --install "${dir}/build"

    # cmake --install runs as root and may drop root-owned files into the config
    # directory; hand them back to the user.
    srun chown -R "${USER}:${USER}" "${dir}"
    ok "shell installed to ${dir}"
}

main() { install_shell "$@"; }
main "$@"
