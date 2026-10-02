<div align="center">

# Caelestia on Fedora

**A one-command, interactive installer that turns a fresh Fedora Workstation into a full
[Caelestia](https://github.com/caelestia-dots) desktop — Quickshell shell, Hyprland session,
CLI and all — with the Fedora-specific workarounds already handled.**

[![Platform](https://img.shields.io/badge/platform-Fedora-51A2DA?style=for-the-badge&labelColor=101418&logo=fedora&logoColor=white)](https://fedoraproject.org)
[![Compositor](https://img.shields.io/badge/compositor-Hyprland-58E1FF?style=for-the-badge&labelColor=101418)](https://hypr.land)
[![Shell](https://img.shields.io/badge/shell-Quickshell-b9c8da?style=for-the-badge&labelColor=101418)](https://quickshell.org)
[![Language](https://img.shields.io/badge/bash-5.x-4EAA25?style=for-the-badge&labelColor=101418&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-d3bfe6?style=for-the-badge&labelColor=101418)](LICENSE)
[![PRs](https://img.shields.io/badge/PRs-welcome-96f1f1?style=for-the-badge&labelColor=101418)](#contributing)

</div>

> [!WARNING]
> **Unofficial, community-made project.** This repository is an independent Fedora installer
> for **[Caelestia](https://github.com/caelestia-dots/caelestia)**. It is **not affiliated with,
> endorsed by, or maintained by the Caelestia project or its authors**, and it is not the
> official installer. For the upstream project, its official (Arch-based) installer and its
> documentation, use **[github.com/caelestia-dots](https://github.com/caelestia-dots)**.

---

## Overview

[Caelestia](https://github.com/caelestia-dots) is a modern, Material-You-styled desktop
built on [Quickshell](https://quickshell.org) and [Hyprland](https://hypr.land). Its official
installer targets Arch Linux, so getting the whole stack running on Fedora means pulling from
several COPRs and RPM Fusion, building a couple of components from source, and applying a
handful of distro-specific fixes.

This repository is an [ml4w](https://github.com/mylinuxforwork/dotfiles)-style, `gum`-powered
installer that automates all of that. Run it on a **fresh Fedora Workstation** and pick the
Caelestia session from GDM when it finishes.

> This project installs Caelestia from its upstream repositories at run time; it does not
> redistribute the shell. For screenshots, a feature tour and the full upstream docs, see the
> [Caelestia shell repository](https://github.com/caelestia-dots/shell) and
> [caelestiashell.com](https://caelestiashell.com).

## Features

- **Interactive TUI** — `gum` menus for the install mode and optional apps; a non-interactive
  `--yes` mode for unattended use.
- **Idempotent and safe** — existing Hyprland and component configs are backed up with a
  `.bak-<timestamp>` suffix; user overrides are only written if absent.
- **Complete stack** — compositor, Quickshell shell, `caelestia` CLI, fonts, dotfiles,
  dependencies and a dedicated GDM/Wayland session.
- **Fedora workarounds built in** — RPM Fusion + COPRs, from-source `libcava` and `M3Shapes`,
  GPU/VA-API probing, service enablement and GTK defaults.
- **Screen recording that actually works** — probes each render node and falls back to a
  supported hardware encoder (details [below](#the-fedora-screen-recording-fix)).
- **Dry-run mode** — `--dry-run` prints every action without touching the system.

## Requirements

| | |
| --- | --- |
| OS | Fedora Workstation 41+ (tested on Fedora 44) |
| Architecture | `x86_64` (also builds on `aarch64` where packages exist) |
| Access | A normal user account with `sudo` — **not** root |
| Network | Internet access during install (packages, COPRs, source clones) |
| Disk | ~3–5 GB for packages, build artifacts and the toolchain |
| GPU | Any Wayland-capable GPU; VA-API/Vulkan packages are installed automatically |

## Quick start

On a fresh Fedora machine, one command clones the installer, then runs it:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FahmiMj/caelestia-fedora/main/bootstrap.sh)
```

Fully unattended (standard set, no prompts):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FahmiMj/caelestia-fedora/main/bootstrap.sh) --yes
```

### From a checkout

```bash
git clone https://github.com/FahmiMj/caelestia-fedora
cd caelestia-fedora
./install.sh
```

### Options

Both entrypoints accept the same flags:

```bash
./install.sh --dry-run     # print the plan, change nothing
./install.sh --yes         # non-interactive, standard set
./install.sh --help
```

| Variable | Default | Purpose |
| --- | --- | --- |
| `CAELESTIA_REF` | `main` | Git ref (branch/tag) of the upstream components to install |

## What gets installed

The installer runs fourteen ordered steps, each a self-contained script in `setup/`:

| Step | Module | Description |
| --- | --- | --- |
| 1 | `preflight` | Verify Fedora/arch, network, `sudo`, disk space; install `gum` |
| 2 | `repos` | Enable RPM Fusion and COPRs (`lionheartp/Hyprland`, `peterwu/rendezvous`, `tofik/nwg-shell`) |
| 3 | `packages` | Install compositor, shell dependencies, audio, networking, apps and tools |
| 4 | `build-deps` | Build `libcava` and the `M3Shapes` QML module from source |
| 5 | `shell` | Build and install the Caelestia Quickshell config into `~/.config/quickshell/caelestia` |
| 6 | `cli` | Install the `caelestia` CLI in an isolated `pipx` environment |
| 7 | `fonts` | Install the bundled Caelestia fonts |
| 8 | `dots` | Deploy the upstream dotfiles plus Fedora user overrides |
| 9 | `session` | Install the **Hyprland (Caelestia)** GDM/Wayland session |
| 10 | `fedora-fixes` | Pick a working GPU video encoder and create a wallpaper folder |
| 11 | `desktop` | Enable services and set GTK/appearance defaults |
| 12 | `gpu` | VA-API/Vulkan packages; optional NVIDIA driver prompt |
| 13 | `extras` | Optional apps chosen in the TUI (firefox, nvim, zed, VS Code, Discord, …) |
| 14 | `finish` | Generate the initial colour scheme and print next steps |

## First login

1. Log out and, at the GDM login screen, pick **Hyprland (Caelestia)** from the session menu
   (the gear icon). Do not run it alongside another Hyprland setup such as ml4w — both
   manage Quickshell and will fight over it.
2. On first start the session launcher execs Hyprland, which autostarts `caelestia shell -d`
   and generates the initial colour scheme from the wallpaper.
3. Open the launcher (default keybind) and explore the shell's settings, bar and utilities.

## The Fedora screen-recording fix

`gpu-screen-recorder` defaults to H.264, but many Intel iGPUs only expose VP9 and JPEG
hardware encoding through VA-API. The installer probes every `/dev/dri/renderD*` node with
`vainfo`; if H.264/HEVC/AV1 encoding is unavailable it writes a codec override to
`~/.config/caelestia/cli.json`:

```json
{ "record": { "extraArgs": ["-k", "vp9"] } }
```

Here `-k` selects the codec (`-c` would select the container). This makes the shell's
recording widget work on hardware that would otherwise silently fall back to software.

## Layout

```
bootstrap.sh                    fresh-install entrypoint (clone + run install.sh)
install.sh                      interactive installer / argument parsing / step runner
setup/                          one script per step (all source setup/_lib.sh)
  _lib.sh                         shared helpers: logging, dnf, COPR, rpmfusion, git
  preflight … finish              the fourteen steps above
config/
  caelestia/                    user overrides: hypr-vars.lua, hypr-user.lua, shell.json
  wayland-sessions/             GDM session entry (hyprland-caelestia.desktop)
  start-hyprland-caelestia      session launcher installed to /usr/local/bin
  fonts/                        bundled fonts (see config/fonts/README.md)
LICENSE                         MIT
```

## Updating

Re-run the installer; user overrides are preserved and upstream components are re-fetched at
the ref named by `CAELESTIA_REF` (default `main`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FahmiMj/caelestia-fedora/main/bootstrap.sh)
```

Note that Caelestia's own `caelestia update` command is Arch-specific; on Fedora, updating
means re-running this installer.

## Uninstalling

There is no automated uninstaller, but the pieces are easy to remove:

```bash
# stop the shell
caelestia shell -k 2>/dev/null || true

# shell config + CLI
rm -rf ~/.config/quickshell/caelestia
pipx uninstall caelestia

# session entry point
sudo rm -f /usr/local/bin/start-hyprland-caelestia
sudo rm -f /usr/share/wayland-sessions/hyprland-caelestia.desktop
```

Remove `~/.config/hypr` and the component configs, or restore the `.bak-*` copies the
installer created, if you want to return to your previous setup.

## Troubleshooting

- **The session doesn't appear in GDM** — confirm
  `/usr/share/wayland-sessions/hyprland-caelestia.desktop` exists and that you are on a
  Wayland-capable GPU/driver.
- **The shell doesn't start** — check `caelestia shell -k` then `caelestia shell -d` from a
  terminal for errors; make sure it is also installed at
  `~/.config/quickshell/caelestia`.
- **Recording produces a black/failed file** — see
  [the recording fix](#the-fedora-screen-recording-fix); some setups need `-c mp4` in the
  same `extraArgs` list.
- **NVIDIA + Secure Boot** — installing `akmod-nvidia` requires enrolling a MOK key or
  disabling Secure Boot. The installer will not do this for you.
- **Optional apps missing** — apps without Fedora packages (Discord, Spotify, VS Code,
  VSCodium, Todoist) are reported with a Flathub install hint rather than installed.

## Contributing

Issues and pull requests are welcome. Please run the linters before submitting:

```bash
shellcheck -x install.sh setup/*.sh bootstrap.sh
./install.sh --yes --dry-run
```

## Credits

- **[Caelestia](https://github.com/caelestia-dots/caelestia)** — the original project: the
  shell, CLI and dotfiles this installer deploys (GPL-3.0). All credit for Caelestia belongs to
  its authors; this repository only automates installing it on Fedora.
- [Hyprland](https://hypr.land), [Quickshell](https://quickshell.org),
  [ml4w](https://github.com/mylinuxforwork/dotfiles) and the various COPR/RPM Fusion
  maintainers whose packaging makes this possible.

## Disclaimer

This is an **unofficial, community-made** Fedora installer for Caelestia. It is **not
affiliated with, endorsed by, or supported by the [Caelestia project](https://github.com/caelestia-dots/caelestia)**
or its authors. Please do **not** report issues with this installer to the upstream project —
use this repository's issue tracker instead.

The installer is provided "as is", without warranty; always review the scripts before running
them, and use them at your own risk.

## License

The installer scripts in this repository are released under the [MIT License](LICENSE).
Caelestia itself is GPL-3.0 and is cloned at run time, not redistributed here. The bundled
fonts remain under their original licenses (SIL OFL 1.1 / Apache 2.0) — see
[`config/fonts/README.md`](config/fonts/README.md).
