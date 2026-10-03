#!/usr/bin/env bash
# Preflight checks: verify the host is a supported Fedora system and that the
# basic tooling (sudo, network, disk space, gum) is available.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

require_fedora() {
    [[ -r /etc/os-release ]] || die "/etc/os-release not found; unsupported system"
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == "fedora" ]] || die "This installer targets Fedora (found ID=${ID:-unknown})"
    case "$(uname -m)" in
        x86_64|aarch64) ;;
        *) die "Unsupported architecture: $(uname -m)" ;;
    esac
    ok "Fedora ${VERSION_ID:-?} (${PRETTY_NAME:-unknown}) on $(uname -m)"
}

require_not_root() {
    [[ "${EUID}" -ne 0 ]] || die "Run as your normal user, not root (sudo is used internally)"
    ok "running as ${USER} (uid ${EUID})"
}

require_network() {
    if ! curl -fsSL --max-time 10 -o /dev/null https://github.com 2>/dev/null; then
        die "No network access to github.com (required to fetch sources and packages)"
    fi
    ok "network reachable"
}

require_sudo() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        info "dry-run: skipping sudo authentication"
        return 0
    fi
    if sudo -n true 2>/dev/null; then
        ok "sudo available (passwordless)"
        return 0
    fi
    if [[ ! -r /dev/tty ]]; then
        die "sudo needs a password but no terminal is available; run interactively or configure NOPASSWD for this user"
    fi
    info "sudo will prompt for your password"
    # shellcheck disable=SC2024  # we want sudo to read the password from the tty
    sudo -v </dev/tty || die "sudo authentication failed"
    ok "sudo available"
}

require_disk() {
    local avail
    avail="$(df -Pk "${HOME}" | awk 'NR==2 {print $4}')"
    if [[ -n "${avail}" && "${avail}" -lt 5242880 ]]; then
        die "Need at least 5 GiB free in ${HOME} (found $((avail/1024)) MiB)"
    fi
    ok "free space in \$HOME: $((avail/1024/1024)) GiB"
}

install_prereqs() {
    dnf_install dnf-plugins-core git curl unzip jq
}

ensure_gum() {
    have_cmd gum && { ok "gum present"; return 0; }
    info "installing gum"
    if [[ "${DRY_RUN}" == "1" ]]; then dry "install gum"; return 0; fi
    if dnf -q list --available gum >/dev/null 2>&1; then
        srun dnf install -y gum
    else
        local ver="0.17.0" arch
        case "$(uname -m)" in
            x86_64) arch="x86_64" ;;
            aarch64) arch="arm64" ;;
            *) die "cannot auto-install gum on $(uname -m)" ;;
        esac
        local tmp
        tmp="$(mktemp -d)"
        curl -fsSL -o "${tmp}/gum.tar.gz" \
            "https://github.com/charmbracelet/gum/releases/download/v${ver}/gum_${ver}_Linux_${arch}.tar.gz"
        tar -xzf "${tmp}/gum.tar.gz" -C "${tmp}" gum
        run mkdir -p "${HOME}/.local/bin"
        install -Dm0755 "${tmp}/gum" "${HOME}/.local/bin/gum"
        rm -rf "${tmp}"
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
    have_cmd gum || die "gum installation failed"
    ok "gum installed"
}

main() {
    section "Preflight"
    require_fedora
    require_not_root
    require_network
    require_sudo
    require_disk
    ensure_dir "${CAELESTIA_STATE}"
    install_prereqs
    ensure_gum
    ok "preflight complete"
}

main "$@"
