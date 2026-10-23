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

    # Fedora quickshell isolation fix:
    # The shell QML imports `qs.services`, `qs.components`, `qs.utils` but the
    # installed tree only has services/, components/, utils/ at the top level
    # (no qs/ namespace directory). Quickshell resolves `import qs.services`
    # relative to the config dir, so create a qs/ symlink namespace.
    # See: https://github.com/FahmiMj/caelestia-fedora (install logs, BUG 5/7)
    local qsdir="${dir}/qs"
    ensure_dir "${qsdir}/components"
    ln -sf ../services  "${qsdir}/services"
    ln -sf ../utils     "${qsdir}/utils"
    ln -sf ../../components/containers "${qsdir}/components/containers"
    ln -sf ../../components/filedialog "${qsdir}/components/filedialog"
    ln -sf ../../components/images     "${qsdir}/components/images"

    ok "shell installed to ${dir}"
}

main() { install_shell "$@"; }
main "$@"
