_:

{
  home.file = {
    ".local/bin/wifi-menu" = {
      source = ./wifi-menu.sh;
      executable = true;
    };
    ".local/bin/bluetooth-menu" = {
      source = ./bluetooth-menu.sh;
      executable = true;
    };
  };

  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 34;
        margin-top = 5;
        margin-left = 10;
        margin-right = 10;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "tray"
          "custom/systemd"
          "custom/ccusage"
          "mpris"
          "privacy"
          "bluetooth"
          "custom/gpu"
          "cpu"
          "memory"
          "temperature"
          "disk"
          "network"
          "wireplumber"
          "custom/mic"
          "custom/dnd"
          "idle_inhibitor"
          "custom/wallpaper"
          "custom/gemini"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            default = "󰊠";
            "1" = "󰨞"; # Development
            "2" = "󰈹"; # Browser
            "3" = "󰝚"; # Music
            "4" = "󰊗"; # Gaming / game dev
            "5" = "󰒓"; # System
            "6" = "󰙯"; # Chat
            "7" = "7";
            "8" = "8";
            "9" = "9";
            active = "󱓻";
            urgent = "󱓻";
          };
          persistent_workspaces = {
            "1" = [ ]; # Dev
            "2" = [ ]; # Browser
            "3" = [ ]; # Music
            "4" = [ ]; # Gaming / game dev
            "5" = [ ]; # System
            "6" = [ ]; # Chat
          };
        };

        "hyprland/submap" = {
          format = " {}";
          max-length = 20;
          tooltip = false;
        };

        cpu = {
          interval = 5;
          format = "󰻠 {}%";
          max-length = 10;
          states = {
            warning = 80;
            critical = 95;
          };
        };

        memory = {
          interval = 5;
          format = "󰍛 {}%";
          max-length = 10;
          states = {
            warning = 80;
            critical = 95;
          };
        };

        tray = {
          spacing = 10;
        };

        clock = {
          tooltip-format = "{calendar}";
          format-alt = "󰃭  {:%a, %d %b %Y}";
          format = "󰥔  {:%I:%M %p}";
        };

        # Filter to wifi interfaces only (wl*) so module always reflects
        # wifi state. Without `interface`, waybar would show ethernet when
        # cabled and hide wifi. Glob keeps it portable across hosts.
        # All format-* keys defined so module renders something in every
        # state (no wifi adapter, radio off, linked-no-IP, disconnected).
        network = {
          interface = "wl*";
          format = "󰖪";
          format-wifi = "{icon}";
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format-ethernet = "";
          format-linked = "󰤫";
          format-disconnected = "󰖪";
          tooltip-format = "No wifi adapter";
          tooltip-format-wifi = "{icon} {essid}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          tooltip-format-linked = "{ifname} (no IP)";
          tooltip-format-disconnected = "Disconnected";
          on-click = "~/.local/bin/wifi-menu";
          on-click-right = "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on";
          on-click-middle = "nm-connection-editor";
          interval = 5;
          nospacing = 1;
        };

        wireplumber = {
          format = "{icon} {volume}%";
          format-bluetooth = "󰂰 {volume}%";
          nospacing = 1;
          tooltip-format = "Volume : {volume}%";
          format-muted = "󰝟";
          format-icons = {
            headphone = "󰋋";
            default = [
              "󰖀"
              "󰕾"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
          on-click-right = "pamixer -t";
          scroll-step = 1;
        };

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "▶";
            spotify = "";
          };
          status-icons = {
            paused = "󰏤";
          };
          dynamic-order = [
            "title"
            "artist"
          ];
          dynamic-separator = " - ";
          dynamic-len = 40;
          max-length = 50;
          ignored-players = [
            "chromium"
            "firefox"
          ];
          tooltip-format = "{player}: {dynamic}";
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
        };

        bluetooth = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-off = "󰂲";
          format-no-controller = "󰂲";
          format-connected = "󰂱 {device_alias}";
          format-connected-battery = "󰂱 {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "~/.local/bin/bluetooth-menu";
          on-click-right = "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on";
          on-click-middle = "blueman-manager";
        };

        temperature = {
          thermal-zone = 1; # x86_pkg_temp (CPU)
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-critical = "{icon} {temperatureC}°C";
          format-icons = [
            "󱃃"
            "󰔏"
            "󱃂"
            "󰸁"
            "󰸁"
          ];
          tooltip = true;
        };

        disk = {
          interval = 60;
          format = "󰋊 {percentage_used}%";
          path = "/";
          tooltip-format = "{used} / {total} ({percentage_used}%)";
          states = {
            warning = 80;
            critical = 90;
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰛊";
          };
          tooltip-format-activated = "Idle inhibitor: on";
          tooltip-format-deactivated = "Idle inhibitor: off";
        };

        privacy = {
          icon-spacing = 4;
          icon-size = 14;
          transition-duration = 250;
          modules = [
            {
              type = "screenshare";
              tooltip = true;
              tooltip-icon-size = 24;
            }
            {
              type = "audio-in";
              tooltip = true;
              tooltip-icon-size = 24;
            }
          ];
        };

        # Continuous mode: single long-running nvidia-smi vs spawning every 5s.
        # awk fflush() keeps output unbuffered so waybar sees each line.
        "custom/gpu" = {
          exec = "nvidia-smi -l 5 --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | awk -F', ' '{printf \"󰢮 %s%% 󰔏 %s°C\\n\", $1, $2; fflush()}'";
          restart-interval = 30;
          format = "{}";
          tooltip-format = "NVIDIA GPU";
        };

        # Signal-driven: no polling. Click toggles + signals waybar to refresh.
        # interval kept as a long safety net in case state drifts.
        "custom/dnd" = {
          exec = "makoctl mode | grep -q do-not-disturb && echo '󰂛' || echo '󰂚'";
          on-click = "makoctl mode -t do-not-disturb && pkill -SIGRTMIN+8 waybar";
          interval = 86400;
          signal = 8;
          format = "{}";
          tooltip-format = "Toggle Do Not Disturb";
        };

        # Collapsed pipeline: single awk does count + format, saves wc spawn.
        "custom/systemd" = {
          exec = "systemctl --failed --no-legend --no-pager 2>/dev/null | awk 'END{if(NR>0) print \"󰀦 \" NR}'";
          interval = 30;
          format = "{}";
          tooltip-format = "Failed systemd units";
        };

        # Today's Claude cost via ccusage daily (offline, no stdin needed).
        # bunx ≈ 7× faster than npx. `bunx @latest` resolves via npm — wrap
        # in `timeout` so a dead network can't hang the module indefinitely.
        "custom/ccusage" = {
          exec = ''timeout 15 bunx ccusage@latest daily -O -j --since "$(date -u +%Y%m%d)" 2>/dev/null | jq -r '.daily[0].totalCost // 0 | "󰚩 $\(. * 100 | round / 100)"' 2>/dev/null || echo '󰚩 --' '';
          interval = 300;
          format = "{}";
          tooltip = false;
        };

        # Microphone: default source volume + mute via wpctl.
        # Signal-driven refresh from media key binding (SIGRTMIN+9).
        "custom/mic" = {
          exec = "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{if(/MUTED/) print \"󰍭\"; else printf \"󰍬 %d%%\\n\", $2*100}'";
          interval = 2;
          signal = 9;
          format = "{}";
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && pkill -SIGRTMIN+9 waybar";
          on-click-right = "pavucontrol -t 4";
          tooltip-format = "Toggle mic mute";
        };

        "custom/gemini" = {
          format = "󰊤";
          tooltip-format = "Ask Gemini";
          on-click = "vicinae toggle";
        };

        # Wallpaper theme indicator. Left/right click cycles wallpapers within
        # the current theme; middle click switches to the next theme. Tooltip
        # refreshes on SIGRTMIN+10 which variety-theme sends after a switch.
        "custom/wallpaper" = {
          exec = ''jq -cn --arg t "$(~/.local/bin/variety-theme current)" '{text:"󰸉",tooltip:"Theme: \($t)\nClick: next wallpaper  |  Right: previous\nMiddle: next theme  |  Scroll: cycle"}' '';
          return-type = "json";
          interval = 60;
          signal = 10;
          format = "{}";
          on-click = "variety -n";
          on-click-right = "variety -p";
          on-click-middle = "~/.local/bin/variety-theme next";
          on-scroll-up = "variety -n";
          on-scroll-down = "variety -p";
        };

        "custom/power" = {
          format = "󰤆";
          tooltip = false;
          on-click = "vicinae vicinae://extensions/vicinae/power";
        };
      };
    };

    style = ''
      @import "colors.css";

      * {
        border: none;
        border-radius: 0;
        min-height: 0;
        font-family: FiraCode Nerd Font;
        font-size: 13px;
      }

      window#waybar {
        background-color: transparent;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      window#waybar.hidden {
        opacity: 0.5;
      }

      /* --- Workspaces --- */

      #workspaces {
        background-color: transparent;
      }

      #workspaces button {
        all: initial;
        min-width: 0;
        box-shadow: inset 0 -3px transparent;
        padding: 6px 18px;
        margin: 6px 3px;
        border-radius: 4px;
        background-color: alpha(@surface_container, 0.7);
        color: @on_surface;
      }

      #workspaces button.active {
        color: @primary;
        background-color: alpha(@surface_container, 0.9);
        box-shadow: inset 0 -2px @primary;
      }

      #workspaces button:hover {
        box-shadow: inherit;
        text-shadow: inherit;
        color: @primary;
        background-color: alpha(@surface_container, 0.85);
      }

      #workspaces button.urgent {
        background-color: alpha(@error, 0.8);
      }

      /* --- Common module styling --- */

      #memory,
      #custom-power,
      #custom-gemini,
      #custom-wallpaper,
      #custom-ccusage,
      #custom-gpu,
      #custom-dnd,
      #custom-mic,
      #custom-systemd,
      #idle_inhibitor,
      #disk,
      #privacy,
      #battery,
      #backlight,
      #wireplumber,
      #network,
      #clock,
      #cpu,
      #tray,
      #submap,
      #mpris,
      #bluetooth,
      #temperature {
        border-radius: 4px;
        margin: 6px 3px;
        padding: 6px 12px;
        background-color: alpha(@surface_container, 0.7);
        color: @on_surface;
      }

      #submap {
        background-color: alpha(@primary, 0.8);
        color: @on_primary;
        font-weight: bold;
        padding: 6px 16px;
      }

      #clock {
        font-family: JetBrainsMono Nerd Font;
      }

      /* --- Module groups (connected pills) --- */

      /* Hardware: gpu → cpu → memory → temperature */
      #custom-gpu {
        border-radius: 4px 0 0 4px;
        margin-right: 0;
      }

      #cpu,
      #memory {
        border-radius: 0;
        margin-left: 0;
        margin-right: 0;
      }

      #temperature {
        border-radius: 0 4px 4px 0;
        margin-left: 0;
      }

      /* IO: disk → network */
      #disk {
        border-radius: 4px 0 0 4px;
        margin-right: 0;
      }

      #network {
        border-radius: 0 4px 4px 0;
        margin-left: 0;
        padding-right: 17px;
      }

      /* Audio: wireplumber (speaker) → custom/mic */
      #wireplumber {
        border-radius: 4px 0 0 4px;
        margin-right: 0;
      }

      #custom-mic {
        border-radius: 0 4px 4px 0;
        margin-left: 0;
      }

      /* Controls: dnd → idle_inhibitor → wallpaper → gemini → power */
      #custom-dnd {
        border-radius: 4px 0 0 4px;
        margin-right: 0;
      }

      #idle_inhibitor,
      #custom-wallpaper,
      #custom-gemini {
        border-radius: 0;
        margin-left: 0;
        margin-right: 0;
      }

      #custom-power {
        border-radius: 0 4px 4px 0;
        margin-left: 0;
        margin-right: 6px;
      }

      /* Subtle dividers between grouped modules */
      #custom-gpu,
      #cpu,
      #memory,
      #disk,
      #wireplumber,
      #custom-dnd,
      #idle_inhibitor,
      #custom-wallpaper,
      #custom-gemini {
        border-right: 1px solid alpha(@outline, 0.15);
      }

      /* --- Semantic colors --- */

      #cpu.warning,
      #memory.warning,
      #disk.warning {
        color: @tertiary;
      }

      #temperature.critical,
      #cpu.critical,
      #memory.critical,
      #disk.critical {
        color: @error;
        font-weight: bold;
      }

      #wireplumber.muted {
        color: @outline;
        opacity: 0.7;
      }

      #idle_inhibitor.activated {
        color: @primary;
      }

      #custom-systemd {
        color: @error;
        font-weight: bold;
      }

      #privacy {
        color: @error;
      }

      /* --- Individual module tweaks --- */

      #mpris {
        padding-left: 16px;
        padding-right: 16px;
      }

      #mpris.paused {
        color: @outline;
      }

      #tray {
        color: @primary;
      }

      /* --- Tooltips --- */

      tooltip {
        border: 1px solid alpha(@primary, 0.3);
        border-radius: 8px;
        padding: 15px;
        background-color: alpha(@surface_container, 0.95);
      }

      tooltip label {
        padding: 5px;
        background-color: alpha(@surface_container, 0.95);
      }
    '';
  };
}
