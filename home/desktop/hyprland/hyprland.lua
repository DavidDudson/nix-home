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

-- Plugin: hyprspace overview panel
hl.config({
    plugin = {
        overview = {
            centerAligned        = true,
            onBottom             = false,
            panelHeight          = 200,
            workspaceMargin      = 12,
            panelBorderWidth     = 2,
            workspaceBorderSize  = 2,
            drawActiveWorkspace  = true,
        },
    },
})

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
    hl.exec_cmd("~/.local/bin/variety-theme start")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("vicinae server")
    hl.exec_cmd("~/.local/bin/fetch-secrets")

    -- Scratchpad apps — hidden special workspaces toggled by F-keys.
    hl.exec_cmd("[workspace special:btop silent] ghostty -e btop")
    hl.exec_cmd("[workspace special:notes silent] zed ~/scratchpad.md")

    -- Hyprspace overview keybind: plugin dispatcher exists only after load,
    -- so register via hyprctl after a short delay.
    hl.exec_cmd("sh -c 'sleep 1 && hyprctl keyword bind \"SUPER, TAB, overview:toggle\"'")
end)
