-- Workspace 1 — Development
hl.window_rule({ match = { class = "code-url-handler" },        workspace = "1" })
hl.window_rule({ match = { class = "jetbrains-rustrover" },     workspace = "1" })

-- Workspace 2 — Browsers
hl.window_rule({ match = { class = "vivaldi-stable" },          workspace = "2" })
hl.window_rule({ match = { class = "Vivaldi-stable" },          workspace = "2" })
hl.window_rule({ match = { class = "firefox" },                 workspace = "2" })
hl.window_rule({ match = { class = "chromium" },                workspace = "2" })

-- Workspace 3 — Music & Media
hl.window_rule({ match = { class = "Spotify" },                 workspace = "3" })
hl.window_rule({ match = { title = "Spotify" },                 workspace = "3" })
hl.window_rule({ match = { class = "vlc" },                     workspace = "3" })

-- Workspace 4 — Gaming & Game Dev
hl.window_rule({ match = { class = "Aseprite" },                workspace = "4" })
hl.window_rule({ match = { class = "aseprite" },                workspace = "4" })
hl.window_rule({ match = { class = "org.mapeditor.Tiled" },     workspace = "4" })
hl.window_rule({ match = { class = "qrenderdoc" },              workspace = "4" })
hl.window_rule({ match = { title = "Tracy Profiler" },          workspace = "4" })
hl.window_rule({ match = { class = "steam" },                   workspace = "4" })
hl.window_rule({ match = { class = "Steam" },                   workspace = "4" })

-- Workspace 5 — System & Settings
hl.window_rule({ match = { class = "1password" },               workspace = "5" })
hl.window_rule({ match = { class = "1Password" },               workspace = "5" })
hl.window_rule({ match = { class = "nwg-look" },                workspace = "5" })

-- Floating dialog apps — pop up centered, sized to a sensible default.
hl.window_rule({
    match  = { class = "(pavucontrol|org\\.pulseaudio\\.pavucontrol)" },
    float  = true,
    center = true,
    size   = "900 650",
})
hl.window_rule({
    match  = { class = "blueman-manager" },
    float  = true,
    center = true,
    size   = "700 500",
})
hl.window_rule({
    match  = { class = "nm-connection-editor" },
    float  = true,
    center = true,
    size   = "800 600",
})

-- Workspace 6 — Chat
hl.window_rule({ match = { class = "discord" },                 workspace = "6" })
hl.window_rule({ match = { class = "Discord" },                 workspace = "6" })

-- Claude popout — right-edge side-panel chat anchored to special:claude.
hl.window_rule({
    match     = { class = "com.popout.claude" },
    float     = true,
    size      = "15% 100%",
    move      = "85% 0",
    workspace = "special:claude silent",
})

-- Suppress maximize events
hl.window_rule({
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Steam/game launcher fix for empty windows
hl.window_rule({
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Smart gaps — only-tiled / only-floating; keep top gap for waybar
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = { top = 10, right = 0, bottom = 0, left = 0 }, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = { top = 10, right = 0, bottom = 0, left = 0 }, gaps_in = 0 })

-- Per-workspace identity gaps. Music breathes; gaming runs flush.
hl.workspace_rule({ workspace = "3", gaps_out = 30 })
hl.workspace_rule({ workspace = "4", gaps_out = 0, gaps_in = 0 })

-- Remove rounding/border on single-window workspaces
hl.window_rule({ match = { workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
hl.window_rule({ match = { workspace = "f[1]" },   border_size = 0, rounding = 0 })

-- Vicinae launcher layer rules
hl.layer_rule({ name = "vicinae-blur",         match = { namespace = "vicinae" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "vicinae-no-animation", match = { namespace = "vicinae" }, no_anim = true })

-- Frosted-glass bars and menus — blur everything behind waybar and rofi.
hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "rofi-blur",   match = { namespace = "rofi" },   blur = true, ignore_alpha = 0 })
