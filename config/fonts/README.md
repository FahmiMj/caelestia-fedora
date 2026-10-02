# Bundled fonts

These fonts are vendored so the installer works on a fresh machine without
network access to font CDNs. Each file remains under its original license.

| File | Upstream project | License |
| --- | --- | --- |
| `CaskaydiaCoveNerdFont-{Regular,Bold}-caelestia.ttf` | [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) (Cascadia Code) | SIL Open Font License 1.1 |
| `MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf` | [Material Symbols](https://github.com/google/material-design-icons) | Apache License 2.0 |
| `Rubik[wght].ttf` | [Rubik](https://github.com/googlefonts/rubik) | SIL Open Font License 1.1 |

The Caelestia Quickshell configuration additionally ships its own copy of
Google Sans Flex under the SIL Open Font License; the shell loads it from its
own assets, so it is not vendored here.
