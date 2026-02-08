{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      monitor = ",preferred,auto,auto";

      "$terminal" = "rio";
      "$fileManager" = "rio -e nu -c yazi";
      "$menu" = "rofi --show drun";
      "$mainMod" = "SUPER";

      exec-once = [
        # Themed workspace apps
        "[workspace 1 silent] code-cursor"      # Development workspace
        "[workspace 1 silent] zed"              # Development workspace
        "[workspace 2 silent] vivaldi"          # Browser workspace
        "[workspace 1 silent] $terminal"        # Terminal on dev workspace

        # System services
        "waybar"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "hyprctl setcursor Bibata-Modern-Classic 24"
        "hyprpaper"
      ];

      env = [
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Bibata-Modern-Classic"
        "HYPRCURSOR_SIZE,24"
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
        "WLR_DRM_NO_ATOMIC,1"
        "__NV_PRIME_RENDER_OFFLOAD,1"
        "GBM_BACKEND,nvidia-drm"
        "NIXOS_OZONE_WL,1"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(ff9900ee) rgba(ff6600ee) 45deg";
        "col.inactive_border" = "rgba(ff990088)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 5;
          color = "rgba(ff9900cc)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.25;
        };
      };

      animations = {
        enabled = true;

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global,1,10,default"
          "border,1,5.39,easeOutQuint"
          "windows,1,4.79,easeOutQuint"
          "windowsIn,1,4.1,easeOutQuint,popin 87%"
          "windowsOut,1,1.49,linear,popin 87%"
          "fadeIn,1,1.73,almostLinear"
          "fadeOut,1,1.46,almostLinear"
          "fade,1,3.03,quick"
          "layers,1,3.81,easeOutQuint"
          "layersIn,1,4,easeOutQuint,fade"
          "layersOut,1,1.5,linear,fade"
          "fadeLayersIn,1,1.79,almostLinear"
          "fadeLayersOut,1,1.39,almostLinear"
          "workspaces,1,1.94,almostLinear,fade"
          "workspacesIn,1,1.21,almostLinear,fade"
          "workspacesOut,1,1.94,almostLinear,fade"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo = false;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = -0.5;
        accel_profile = "adaptive";

        touchpad = {
          natural_scroll = false;
        };
      };

      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      # Keybindings
      bind = [
        # App launching (i3-like)
        "$mainMod, RETURN, exec, $terminal"
        "$mainMod, Q, killactive,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod SHIFT, SPACE, togglefloating,"
        "$mainMod, F, fullscreen"
        "$mainMod, SPACE, exec, rofi -show drun -show-icons"

        # Layout controls (i3-like)
        "$mainMod, S, togglesplit,"     # toggle split direction
        "$mainMod, W, togglegroup,"     # toggle stacked/tabbed group (like i3 stacking)
        "$mainMod, A, changegroupactive, f"   # next window in stack
        "$mainMod SHIFT, A, changegroupactive, b"   # previous window in stack

        # Focus (vim keys)
        "$mainMod, H, movefocus, l"
        "$mainMod, J, movefocus, d"
        "$mainMod, K, movefocus, u"
        "$mainMod, L, movefocus, r"

        # Focus (arrow keys)
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Move windows (vim keys)
        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, J, movewindow, d"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod SHIFT, L, movewindow, r"

        # Move windows (arrow keys)
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"

        # Resize windows (vim keys) - i3-like resize mode alternative
        "$mainMod CTRL, H, resizeactive, -40 0"
        "$mainMod CTRL, L, resizeactive, 40 0"
        "$mainMod CTRL, K, resizeactive, 0 -40"
        "$mainMod CTRL, J, resizeactive, 0 40"

        # Resize windows (arrow keys)
        "$mainMod CTRL, left, resizeactive, -40 0"
        "$mainMod CTRL, right, resizeactive, 40 0"
        "$mainMod CTRL, up, resizeactive, 0 -40"
        "$mainMod CTRL, down, resizeactive, 0 40"

        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move to workspace (i3-style)
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Move to workspace silently (follow window)
        "$mainMod CTRL SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod CTRL SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod CTRL SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod CTRL SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod CTRL SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod CTRL SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod CTRL SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod CTRL SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod CTRL SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod CTRL SHIFT, 0, movetoworkspacesilent, 10"

        # Scratchpad (i3-like)
        "$mainMod, minus, togglespecialworkspace, magic"
        "$mainMod SHIFT, minus, movetoworkspace, special:magic"

        # Switch workspaces relative
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        "ALT, TAB, workspace, e+1"
        "ALT SHIFT, TAB, workspace, e-1"

        # Reload config (i3-like)
        "$mainMod SHIFT, C, exec, hyprctl reload"

        # Exit/restart
        "$mainMod SHIFT, E, exit,"
        "$mainMod SHIFT, R, exec, hyprctl reload"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      bindl = [
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPause, exec, playerctl play-pause"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioPrev, exec, playerctl previous"
      ];

      windowrule = [
        "match:class code-url-handler, workspace 1"
        "match:class vivaldi-stable, workspace 2"
        "match:class Vivaldi-stable, workspace 2"
        "match:class firefox, workspace 2"
        "match:class chromium, workspace 2"
        "match:class Spotify, workspace 3"
        "match:title Spotify, workspace 3"
      ];
    };

    # i3-style resize mode submap
    extraConfig = ''
      windowrule = match:class .*, suppress_event maximize

      # Steam/game launcher fix for empty windows
      windowrule = match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus on

      # Resize mode bindings
      bind = $mainMod, R, submap, resize
      submap = resize
      binde = , H, resizeactive, -40 0
      binde = , L, resizeactive, 40 0
      binde = , K, resizeactive, 0 -40
      binde = , J, resizeactive, 0 40
      binde = , left, resizeactive, -40 0
      binde = , right, resizeactive, 40 0
      binde = , up, resizeactive, 0 -40
      binde = , down, resizeactive, 0 40
      bind = , escape, submap, reset
      bind = , RETURN, submap, reset
      submap = reset
    '';
  };

  # Hyprpaper configuration
  home.file.".config/hypr/hyprpaper.conf".text = ''
    wallpaper {
      monitor = 
      path = ~/Pictures/Wallpapers/sunflower.jpg
      fit_mode = cover
    }
    splash = false
    ipc = off
  '';
}
