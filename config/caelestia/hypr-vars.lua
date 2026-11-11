-- User overrides for the Caelestia Hyprland variables.
-- Any key defined here replaces the upstream default in hypr/variables.lua.
-- See: https://github.com/caelestia-dots/caelestia/blob/main/hypr/variables.lua
return {
    -- Match the apps this installer actually installs; the upstream defaults
    -- reference kitty (terminal), sweet-cursors (cursor) and pwvucontrol
    -- (audio settings), none of which are part of the Fedora package set.
    terminal      = "foot",
    kbTerminal    = "SUPER + RETURN",
    editor        = "gnome-text-editor",
    audioSettings = "pavucontrol",
    cursorTheme   = "Bibata-Modern-Ice",
}
