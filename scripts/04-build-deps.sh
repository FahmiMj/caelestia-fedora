#!/usr/bin/env bash
# Build and install the two native dependencies that are not packaged for
# Fedora: libcava (audio visualiser) and the M3Shapes QML module.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"
# shellcheck source=scripts/lib/packages.sh
source "${SCRIPT_DIR}/lib/packages.sh"

section() { printf '\n  == %s ==\n' "$1"; }

pkg_build_deps() {
    section "Build dependencies"
    dnf_install \
        cmake ninja-build meson gcc-c++ pkgconf-pkg-config git \
        qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel \
        fftw-devel inih-devel iniparser-devel \
        libqalculate-devel pipewire-devel aubio-devel lm_sensors-devel
}

build_libcava() {
    section "Building libcava"
    local dir="${CAELESTIA_SRC}/cava"
    git_sync "${CAVA_REPO}" "${dir}"
    rm -rf "${dir}/build"
    # Install to /usr (not /usr/local) so libcava.pc lands on pkg-config's
    # default search path and the shell's cmake can resolve it.
    meson setup "${dir}/build" "${dir}" \
        --prefix=/usr --buildtype=release -Dbuild_target=lib
    ninja -C "${dir}/build"
    caelestia_sudo ninja -C "${dir}/build" install
    caelestia_sudo ldconfig
    ok "libcava installed to /usr"
}

build_m3shapes() {
    section "Building M3Shapes"
    local dir="${CAELESTIA_SRC}/m3shapes"
    git_sync "${M3SHAPES_REPO}" "${dir}"
    rm -rf "${dir}/build"
    cmake -B "${dir}/build" -S "${dir}" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/ \
        -DBUILD_TESTING=OFF
    cmake --build "${dir}/build"
    caelestia_sudo cmake --install "${dir}/build"
    ok "M3Shapes installed"
}

main() {
    pkg_build_deps
    build_libcava
    build_m3shapes
    ok "native dependencies built"
}

main "$@"
