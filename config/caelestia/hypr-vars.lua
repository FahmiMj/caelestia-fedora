-- User overrides for the Caelestia Hyprland variables.
-- Any key defined here replaces the upstream default in hypr/variables.lua.
-- See: https://github.com/caelestia-dots/caelestia/blob/main/hypr/variables.lua
return {
    terminal      = "foot",
    browser       = "firefox",
    editor        = "gnome-text-editor",
    fileExplorer  = "thunar",
    audioSettings = "pavucontrol",
    cursorTheme   = "Bibata-Modern-Ice",
    cursorSize    = 24,

    -- Keybinds, ported from the ml4w defaults used on the maintainer's machine.
    -- SUPER+M is remapped from the music workspace to maximise so it matches
    -- the ml4w "maximise window" bind.
    kbGoToWs                   = "SUPER",
    kbMoveWinToWs              = "SUPER + SHIFT",
    kbTerminal                 = "SUPER + RETURN",
    kbBrowser                  = "SUPER + B",
    kbFileExplorer             = "SUPER + E",
    kbEditor                   = "SUPER + C",
    kbToggleWindowFloating     = "SUPER + T",
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + M",
    kbCloseWindow              = "SUPER + Q",
    kbToggleGroup              = "SUPER + G",
    kbSpecialWs                = "SUPER + S",
    kbMusicWs                  = "SUPER + ALT + M",
    kbScreenshot               = "SUPER + PRINT",
    kbLauncher                 = "SUPER + CTRL + RETURN",
    kbSession                  = "SUPER + CTRL + P",
    kbShowSidebar              = "SUPER + CTRL + S",
    kbLock                     = "SUPER + CTRL + L",
    kbClipboard                = "SUPER + V",
    kbEmoji                    = "SUPER + CTRL + E",
}
