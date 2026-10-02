#!/usr/bin/env bash
# Build and install the two native dependencies that are not packaged for
# Fedora: libcava (audio visualiser) and the M3Shapes QML module.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

pkg_build_deps() {
    section "Build dependencies"
    dnf_install \
        cmake ninja-build meson gcc-c++ pkgconf-pkg-config git \
        qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel \
        fftw-devel inih-devel
}

build_libcava() {
    section "Building libcava"
    local dir="${CAELESTIA_SRC}/cava"
    git_sync "${CAVA_REPO}" "${dir}"
    run rm -rf "${dir}/build"
    run meson setup "${dir}/build" \
        --prefix=/usr/local --buildtype=release -Dbuild_target=lib
    run ninja -C "${dir}/build"
    srun ninja -C "${dir}/build" install
    srun ldconfig
    ok "libcava installed to /usr/local"
}

build_m3shapes() {
    section "Building M3Shapes"
    local dir="${CAELESTIA_SRC}/m3shapes"
    git_sync "${M3SHAPES_REPO}" "${dir}"
    run rm -rf "${dir}/build"
    run cmake -B "${dir}/build" -S "${dir}" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/ \
        -DBUILD_TESTING=OFF
    run cmake --build "${dir}/build"
    srun cmake --install "${dir}/build"
    ok "M3Shapes installed"
}

main() {
    pkg_build_deps
    build_libcava
    build_m3shapes
    ok "native dependencies built"
}

main "$@"
