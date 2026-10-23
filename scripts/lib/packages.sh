#!/usr/bin/env bash
# DNF package helpers for the Caelestia Fedora installer.
# Adapted from setup/_lib.sh.

if [[ -z "${CAELESTIA_PACKAGES_LOADED:-}" ]]; then
CAELESTIA_PACKAGES_LOADED=1

pkg_installed() { rpm -q "$1" >/dev/null 2>&1; }

pkg_available() {
    pkg_installed "$1" && return 0
    dnf -q list --available "$1" >/dev/null 2>&1
}

# Install only the packages that are present in the enabled repositories.
dnf_install() {
    local pkg
    local -a want=()
    for pkg in "$@"; do
        if pkg_installed "${pkg}"; then
            info "already installed: ${pkg}"
            continue
        fi
        if pkg_available "${pkg}"; then
            want+=("${pkg}")
        else
            warn "not available in enabled repos, skipping: ${pkg}"
        fi
    done
    if [[ ${#want[@]} -eq 0 ]]; then
        ok "nothing to install"
        return 0
    fi
    info "dnf install: ${want[*]}"
    if ! caelestia_sudo dnf install -y --skip-unavailable "${want[@]}"; then
        warn "some packages could not be installed together; retrying with --skip-broken"
        caelestia_sudo dnf install -y --skip-unavailable --skip-broken "${want[@]}" \
            || warn "some packages failed to install; review the output above"
    fi
}

copr_enable() {
    local copr="$1"
    local owner="${copr%%/*}" name="${copr##*/}"
    local repo="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${owner}:${name}.repo"
    if [[ -f "${repo}" ]]; then
        info "COPR already enabled: ${copr}"
        return 0
    fi
    info "enabling COPR: ${copr}"
    caelestia_sudo dnf copr enable -y "${copr}"
}

rpmfusion_enable() {
    local rel repo
    rel="$(rpm -E %fedora)"
    repo="/etc/yum.repos.d/rpmfusion-free.repo"
    if [[ ! -f "${repo}" ]]; then
        info "enabling RPM Fusion (free)"
        caelestia_sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${rel}.noarch.rpm"
    else
        info "RPM Fusion (free) already enabled"
    fi
    repo="/etc/yum.repos.d/rpmfusion-nonfree.repo"
    if [[ ! -f "${repo}" ]]; then
        info "enabling RPM Fusion (nonfree)"
        caelestia_sudo dnf install -y \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${rel}.noarch.rpm"
    else
        info "RPM Fusion (nonfree) already enabled"
    fi
}

fi # CAELESTIA_PACKAGES_LOADED
