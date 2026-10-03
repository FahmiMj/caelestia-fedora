-- Fedora-specific additions for the Caelestia session.
-- This file is required last by hypr/hyprland.lua, so it can register
-- hyprland.start hooks or add window rules without editing upstream files.

hl.on("hyprland.start", function()
    -- Fedora uses hyprpolkitagent instead of the Arch-oriented polkit-gnome path
    -- referenced by the upstream hyprland/execs.lua.
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- The geoclue demo agent lives under libexec on Fedora; the upstream path
    -- (/usr/lib/geoclue-2.0/demos/agent) does not exist here.
    hl.exec_cmd("/usr/libexec/geoclue-2.0/demos/agent")
end)
