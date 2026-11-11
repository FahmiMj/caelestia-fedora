#!/usr/bin/env bash
# Install the Caelestia Quickshell config: build the QML plugin/module and place
# the config in ~/.config/quickshell/caelestia.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"
# shellcheck source=scripts/lib/packages.sh
source "${SCRIPT_DIR}/lib/packages.sh"
# shellcheck source=scripts/lib/install-fs.sh
source "${SCRIPT_DIR}/lib/install-fs.sh"

section() { printf '\n  == %s ==\n' "$1"; }

install_shell() {
    section "Caelestia shell"
    dnf_install quickshell

    local dir="${XDG_CONFIG_HOME}/quickshell/caelestia"
    ensure_dir "${XDG_CONFIG_HOME}/quickshell"
    git_sync "${CAELESTIA_SHELL_REPO}" "${dir}" "${CAELESTIA_REF}"

    info "configuring (cmake)"
    cmake -B "${dir}/build" -S "${dir}" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/ \
        -DDISTRIBUTOR=Fedora \
        -DINSTALL_QSCONFDIR="${dir}"
    info "building"
    cmake --build "${dir}/build"
    info "installing (sudo)"
    caelestia_sudo cmake --install "${dir}/build"

    # cmake --install runs as root and may drop root-owned files into the config
    # directory; hand them back to the user.
    caelestia_sudo chown -R "${USER}:$(id -gn)" "${dir}"

    # Quickshell resolves `import qs.<path>` relative to the directory that
    # holds shell.qml, and shell.qml imports qs.services, qs.daemons,
    # qs.modules.* and qs.components.*. Mirror every imported top-level
    # directory into a qs/ namespace so all of those imports resolve.
    local qsdir="${dir}/qs" sub
    ensure_dir "${qsdir}"
    for sub in components daemons modules services utils; do
        [[ -d "${dir}/${sub}" ]] || continue
        ln -sfn "../${sub}" "${qsdir}/${sub}"
    done

    ok "shell installed to ${dir}"
}

main() { install_shell "$@"; }
main "$@"
