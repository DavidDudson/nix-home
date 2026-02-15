_:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 34;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "tray"
          "custom/ccusage"
          "mpris"
          "bluetooth"
          "cpu"
          "memory"
          "temperature"
          "network"
          "wireplumber"
          "custom/gemini"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            default = "󰊠";
            "1" = "󰨞"; # Development workspace
            "2" = "󰈹"; # Browser workspace
            "3" = "󰝚"; # Music workspace
            "4" = "4";
            "5" = "5";
            "6" = "6";
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
            "4" = [ ];
            "5" = [ ];
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
        };

        memory = {
          interval = 5;
          format = "󰍛 {}%";
          max-length = 10;
        };

        tray = {
          spacing = 10;
        };

        clock = {
          tooltip-format = "{calendar}";
          format-alt = "󰃭  {:%a, %d %b %Y}";
          format = "󰥔  {:%I:%M %p}";
        };

        network = {
          format-wifi = "{icon}";
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format-ethernet = "󰀂";
          format-alt = "󱛇";
          format-disconnected = "󰖪";
          tooltip-format-wifi = "{icon} {essid}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          tooltip-format-ethernet = "󰀂  {ifname}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          tooltip-format-disconnected = "Disconnected";
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
          on-click = "~/.config/rofi/audio-sink.sh";
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
          tooltip-format = "{player}: {dynamic}";
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
        };

        bluetooth = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-off = "󰂲";
          format-connected = "󰂱 {device_alias}";
          format-connected-battery = "󰂱 {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        temperature = {
          thermal-zone = 2;
          hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
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

        "custom/ccusage" = {
          exec = "npx ccusage@latest statusline 2>/dev/null || echo '󰚩 --'";
          interval = 300;
          format = "{}";
          tooltip = false;
        };

        "custom/gemini" = {
          format = "󰊤";
          tooltip-format = "Ask Gemini";
          on-click = "~/.config/rofi/gemini.sh &";
        };

        "custom/power" = {
          format = "󰤆";
          tooltip = false;
          on-click = "~/.config/rofi/powermenu.sh &";
        };
      };
    };

    style = ''
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
        background-color: rgba(20,20,20,0.7);
        color: #fff3e0;
      }

      #workspaces button.active {
        color: #ff8800;
        background-color: rgba(20,20,20,0.9);
      }

      #workspaces button:hover {
        box-shadow: inherit;
        text-shadow: inherit;
        color: #ff8800;
        background-color: rgba(20,20,20,0.85);
      }

      #workspaces button.urgent {
        background-color: rgba(255,87,34,0.8);
      }

      #memory,
      #custom-power,
      #custom-gemini,
      #custom-ccusage,
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
        background-color: rgba(20,20,20,0.7);
        color: #fff3e0;
      }

      #submap {
        background-color: rgba(255,136,0,0.8);
        color: #000000;
        font-weight: bold;
        padding: 6px 16px;
      }

      #custom-power {
        margin-right: 6px;
      }

      #network {
        padding-right: 17px;
      }

      #clock {
        font-family: JetBrainsMono Nerd Font;
      }

      tooltip {
        border-radius: 8px;
        padding: 15px;
        background-color: rgba(20,20,20,0.95);
      }

      tooltip label {
        padding: 5px;
        background-color: rgba(20,20,20,0.95);
      }

      #tray {
        color: #ff8800;
      }

      #mpris {
        padding-left: 16px;
        padding-right: 16px;
      }

      #mpris.paused {
        color: #999999;
      }

      #temperature.critical {
        color: #ff5722;
        font-weight: bold;
      }
    '';
  };
}
