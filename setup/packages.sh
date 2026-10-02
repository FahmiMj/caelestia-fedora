#!/usr/bin/env bash
# Install all runtime packages grouped by role.
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/_lib.sh
source "${REPO_DIR}/setup/_lib.sh"

pkg_core() {
    section "Core: compositor, shell and session"
    dnf_install \
        hyprland hyprpicker hyprcursor \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
        quickshell \
        polkit hyprpolkitagent gnome-keyring

    section "Core: shell dependencies"
    dnf_install \
        ddcutil brightnessctl lm_sensors aubio libqalculate \
        power-profiles-daemon

    section "Core: audio"
    dnf_install \
        pipewire pipewire-pulseaudio pipewire-alsa \
        pipewire-jack-audio-connection-kit wireplumber pavucontrol

    section "Core: networking and bluetooth"
    dnf_install NetworkManager bluez

    section "Core: desktop utilities"
    dnf_install \
        wl-clipboard cliphist trash-cli libnotify playerctl \
        grim slurp swappy fuzzel jq curl unzip \
        xdg-user-dirs
}

pkg_desktop() {
    section "Desktop basics"
    dnf_install \
        adw-gtk3-theme papirus-icon-theme \
        nwg-look nwg-displays \
        qt6ct qt6-qtbase qt6-qtdeclarative qt6-qtimageformats \
        qt6-qt5compat qt6-qtsvg qt6-qtwayland \
        noto-fonts noto-fonts-cjk noto-fonts-emoji \
        google-rubik-fonts cascadia-code-nf-fonts \
        bibata-cursor-themes gammastep geoclue2
}

pkg_apps() {
    section "Default applications"
    dnf_install \
        foot fish fastfetch btop micro thunar firefox gnome-text-editor
    section "Shell tools"
    dnf_install \
        eza zoxide direnv bat ripgrep ydotool lazygit \
        jetbrains-mono-fonts
}

pkg_gpu() {
    section "GPU / media acceleration"
    dnf_install \
        libva-utils mesa-va-drivers mesa-vulkan-drivers vulkan-loader \
        intel-media-driver gpu-screen-recorder
}

main() {
    pkg_core
    pkg_desktop
    pkg_apps
    pkg_gpu
    ok "packages installed"
}

main "$@"
