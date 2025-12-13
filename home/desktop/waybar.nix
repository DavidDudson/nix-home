{ config, lib, pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 34;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "tray" "cpu" "memory" "network" "wireplumber" "custom/power" ];

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            default = "";
            "1" = "1";
            "2" = "2";
            "3" = "3";
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
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
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
          format-alt = "  {:%a, %d %b %Y}";
          format = "  {:%I:%M %p}";
        };

        network = {
          format-wifi = "{icon}";
          format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
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
          format = "{icon}";
          format-bluetooth = "󰂰";
          nospacing = 1;
          tooltip-format = "Volume : {volume}%";
          format-muted = "󰝟";
          format-icons = {
            headphone = "";
            default = ["󰖀" "󰕾" ""];
          };
          on-click = "pamixer -t";
          scroll-step = 1;
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
      #battery,
      #backlight,
      #wireplumber,
      #network,
      #clock,
      #cpu,
      #tray {
        border-radius: 4px;
        margin: 6px 3px;
        padding: 6px 12px;
        background-color: rgba(20,20,20,0.7);
        color: #fff3e0;
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
    '';
  };
}
