# Caelestia on Fedora

An interactive, [ml4w](https://github.com/mylinuxforwork/dotfiles)-style installer
that sets up the full [Caelestia](https://github.com/caelestia-dots) desktop —
Quickshell shell, Hyprland session, CLI, dotfiles and Fedora workarounds — on a
fresh Fedora Workstation.

## What it does

| Step | Module | Description |
| --- | --- | --- |
| 1 | `preflight` | Verify Fedora/arch, network, sudo, disk space; install `gum` |
| 2 | `repos` | Enable RPM Fusion and the required COPRs (`lionheartp/Hyprland`, `peterwu/rendezvous`, `tofik/nwg-shell`) |
| 3 | `packages` | Install compositor, shell dependencies, audio, networking, apps and tools |
| 4 | `build-deps` | Build `libcava` and the `M3Shapes` QML module from source |
| 5 | `shell` | Build and install the Caelestia Quickshell config into `~/.config/quickshell/caelestia` |
| 6 | `cli` | Install the `caelestia` CLI via `pipx` |
| 7 | `fonts` | Install the Caelestia fonts (vendored in `config/fonts`) |
| 8 | `dots` | Deploy the upstream dotfiles and Fedora user overrides |
| 9 | `session` | Install the **Hyprland (Caelestia)** GDM/Wayland session |
| 10 | `fedora-fixes` | Pick a working GPU video encoder and create a wallpaper folder |
| 11 | `desktop` | Enable services and set GTK/appearance defaults |
| 12 | `gpu` | VA-API/Vulkan packages; optional NVIDIA driver prompt |
| 13 | `extras` | Optional apps (starship, editor integration, …) |
| 14 | `finish` | Generate the initial colour scheme and print next steps |

## Quick start (fresh Fedora install)

This repository is **private**, so the fresh machine has to authenticate with
GitHub first. The simplest path uses the GitHub CLI:

```bash
# on the fresh Fedora machine
sudo dnf install -y gh
gh auth login
gh repo clone FahmiMj/caelestia-fedora ~/.cache/caelestia-fedora/repo
bash ~/.cache/caelestia-fedora/repo/install.sh
```

For a fully unattended install, append `--yes`:

```bash
bash ~/.cache/caelestia-fedora/repo/install.sh --yes
```

`bootstrap.sh` supports the same authenticated flow once `gh auth login` has
configured the git credential helper:

```bash
gh auth login
bash <(gh api repos/FahmiMj/caelestia-fedora/contents/bootstrap.sh \
        -H "Accept: application/vnd.github.raw")
```

If you make the repository public, the short anonymous form also works:

```bash
CAELESTIA_FEDORA_REPO=https://github.com/FahmiMj/caelestia-fedora.git \
  bash <(curl -fsSL https://raw.githubusercontent.com/FahmiMj/caelestia-fedora/main/bootstrap.sh)
```

### From a local checkout

```bash
gh repo clone FahmiMj/caelestia-fedora
cd caelestia-fedora
./install.sh
```

Options (work with both `install.sh` and `bootstrap.sh`):

```bash
./install.sh --dry-run     # print the plan, change nothing
./install.sh --yes         # non-interactive, standard set
./install.sh --help
```

## The Fedora screen-recording fix

`gpu-screen-recorder` defaults to H.264, but many Intel iGPUs only expose VP9
(and JPEG) hardware encoding via VA-API. The installer probes every
`/dev/dri/renderD*` node with `vainfo`; if H.264/HEVC/AV1 encode is unavailable
it writes a codec override to `~/.config/caelestia/cli.json`:

```json
{ "record": { "extraArgs": ["-k", "vp9"] } }
```

(`-k` selects the codec; `-c` would select the container.)

## Layout

```
bootstrap.sh          fresh-install entrypoint (clone + run install.sh)
install.sh            interactive installer
setup/                one script per step (all source setup/_lib.sh)
config/
  caelestia/          user overrides: hypr-vars.lua, hypr-user.lua, shell.json, cli.json
  wayland-sessions/   GDM session entry
  start-hyprland-caelestia   session launcher
  fonts/              Caelestia fonts (OFL / MIT licensed)
  wallpaper.webp      default wallpaper
```

## Notes and caveats

- The user overrides in `config/caelestia/` are only written if they do not
  already exist, so re-running the installer will not clobber your customisation.
  Existing `~/.config/hypr` and component configs are backed up with a
  `.bak-<timestamp>` suffix.
- Optional apps not packaged for Fedora (Discord, Spotify, VS Code, VSCodium,
  Todoist) are reported with a Flathub install hint instead of being installed.
- Installing the NVIDIA driver (`akmod-nvidia`) on a Secure Boot system requires
  enrolling a MOK key or disabling Secure Boot; the installer will not do this
  for you.
- This installer is intended to be run from a normal user account with `sudo`
  access, not as root.

## Font licenses

The fonts in `config/fonts/` are redistributed under their original licenses
(SIL Open Font License): CaskaydiaCove Nerd Font, Material Symbols Rounded,
Rubik and Google Sans Flex. See `config/fonts/GoogleSansFlex-LICENSE`.
