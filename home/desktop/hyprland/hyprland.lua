-- Hyprland main Lua config (entry point appended by Home Manager)

-- Monitors
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Environment variables
hl.env("XCURSOR_THEME",              "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE",               "24")
hl.env("HYPRCURSOR_THEME",           "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE",            "24")
hl.env("LIBVA_DRIVER_NAME",          "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME",  "nvidia")
hl.env("WLR_NO_HARDWARE_CURSORS",    "1")
hl.env("WLR_DRM_NO_ATOMIC",          "1")
hl.env("__NV_PRIME_RENDER_OFFLOAD",  "1")
hl.env("GBM_BACKEND",                "nvidia-drm")
hl.env("NIXOS_OZONE_WL",             "1")

-- Misc
hl.config({
    misc = {
        focus_on_activate = true,
    },
})

local colors = require("colors")

-- Plugin keys aren't registered at the initial config parse, so apply them
-- via config.reloaded — which fires after each plugin's PLUGIN_INIT calls
-- reloadConfig() and the re-parse completes with plugin keys available.
hl.on("config.reloaded", function()
    -- hyprspace: workspace overview panel
    hl.keyword("plugin:overview:centerAligned",       "true")
    hl.keyword("plugin:overview:onBottom",            "false")
    hl.keyword("plugin:overview:panelHeight",         "200")
    hl.keyword("plugin:overview:workspaceMargin",     "12")
    hl.keyword("plugin:overview:panelBorderWidth",    "2")
    hl.keyword("plugin:overview:workspaceBorderSize", "2")
    hl.keyword("plugin:overview:drawActiveWorkspace", "true")
    hl.keyword("bind", "SUPER, TAB, overview:toggle")

    -- hyprbars: 2px top accent strip in primary color, no text, no buttons.
    -- Matugen drives the color (primary). Sits over the border (precedence)
    -- so it reads as a focus hint. Hidden on unfocused windows via
    -- windowrulev2 (focus:0 selector), mirroring the waybar workspace pill.
    hl.keyword("plugin:hyprbars:bar_height",                 "2")
    hl.keyword("plugin:hyprbars:bar_color",                  colors.primary)
    hl.keyword("plugin:hyprbars:bar_text_size",              "0")
    hl.keyword("plugin:hyprbars:bar_buttons_alignment",      "none")
    hl.keyword("plugin:hyprbars:bar_part_of_window",         "false")
    hl.keyword("plugin:hyprbars:bar_precedence_over_border", "true")
    hl.keyword("plugin:hyprbars:bar_padding",                "0")
    hl.keyword("windowrulev2", "nobar, focus:0")
end)

-- Sub-configs
require("appearance")
require("input")
require("keybindings")
require("rules")

-- Autostart (additional commands; Home Manager auto-injects plugin loaders)
hl.on("hyprland.start", function()
    hl.exec_cmd("[workspace 1 silent] zed")
    hl.exec_cmd("[workspace 2 silent] vivaldi")
    hl.exec_cmd("[workspace 1 silent] ghostty")
    hl.exec_cmd("[workspace 5 silent] 1password")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("vicinae server")
    -- fetch-secrets before variety-theme so the Wallhaven API key is on
    -- disk when variety-theme injects it into the active profile conf.
    hl.exec_cmd("sh -c '~/.local/bin/fetch-secrets && ~/.local/bin/variety-theme start'")

    -- Scratchpad apps — hidden special workspaces toggled by F-keys.
    hl.exec_cmd("[workspace special:btop silent] ghostty -e btop")
    hl.exec_cmd("[workspace special:notes silent] zed ~/scratchpad.md")

end)
