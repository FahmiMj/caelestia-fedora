#!/usr/bin/env bash
# Uninstall Caelestia from Fedora.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/scripts/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/scripts/lib/privileges.sh"

section() {
    echo
    echo "-------------------------------------------------------------"
    echo "  $1"
    echo "-------------------------------------------------------------"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

section "Caelestia Uninstaller"

echo " This will remove Caelestia shell files and configs."
echo

caelestia_prime_sudo || die "Failed to obtain sudo privileges."
trap 'caelestia_stop_sudo_keepalive; true' EXIT

echo
read -r -p "Are you sure you want to uninstall Caelestia? [y/N]: " _confirm
[[ "${_confirm,,}" == "y" || "${_confirm,,}" == "yes" ]] || die "Uninstall cancelled."

echo
read -r -p "Remove installed packages as well? [y/N]: " _remove_pkgs
REMOVE_PACKAGES=false
[[ "${_remove_pkgs,,}" == "y" || "${_remove_pkgs,,}" == "yes" ]] && REMOVE_PACKAGES=true

section "Stopping the shell"
if have_cmd caelestia; then
    caelestia shell -k 2>/dev/null || true
elif [[ -x "$HOME/.local/bin/caelestia" ]]; then
    "$HOME/.local/bin/caelestia" shell -k 2>/dev/null || true
fi

section "Removing shell config and CLI"
rm -rf "${HOME}/.config/quickshell/caelestia"
if have_cmd pipx; then
    pipx uninstall caelestia 2>/dev/null || true
fi
rm -f "${HOME}/.local/bin/caelestia"

section "Removing session entry"
caelestia_sudo rm -f /usr/local/bin/start-hyprland-caelestia
caelestia_sudo rm -f /usr/share/wayland-sessions/hyprland-caelestia.desktop

section "Removing user configs"
rm -rf "${HOME}/.config/caelestia"
rm -rf "${HOME}/.config/caelestia-hypr"
rm -rf "${HOME}/.config/caelestia-fish"
rm -rf "${HOME}/.config/caelestia-foot"
rm -rf "${HOME}/.config/caelestia-fastfetch"
rm -rf "${HOME}/.config/caelestia-btop"
rm -rf "${HOME}/.config/caelestia-micro"
rm -rf "${HOME}/.config/caelestia-thunar"
rm -rf "${HOME}/.config/caelestia-uwsm"
rm -f "${HOME}/.config/caelestia-starship.toml"

if [[ "$REMOVE_PACKAGES" == "true" ]]; then
    section "Removing packages"
    caelestia_sudo dnf remove -y \
        hyprland xdg-desktop-portal-hyprland quickshell \
        foot fish fastfetch btop micro thunar firefox \
        || warn "Some packages could not be removed."
fi

section "Uninstall complete"
ok "Caelestia has been removed. You may want to reboot to clear all services."
