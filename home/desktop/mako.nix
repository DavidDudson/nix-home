{ config, lib, pkgs, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      # Appearance
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#89b4fa";
      progress-color = "over #313244";

      # Layout
      width = 400;
      height = 150;
      margin = "20";
      padding = "15";
      border-size = 2;
      border-radius = 10;

      # Icons
      icons = true;
      max-icon-size = 64;
      icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";

      # Behavior
      default-timeout = 5000;
      ignore-timeout = true;

      # Font
      font = "FiraCode Nerd Font 11";

      # Positioning
      anchor = "top-right";
    };

    # Urgency-specific styling
    extraConfig = ''
      [urgency=low]
      border-color=#89b4fa
      default-timeout=3000

      [urgency=normal]
      border-color=#89b4fa
      default-timeout=5000

      [urgency=high]
      border-color=#f38ba8
      default-timeout=0
      text-color=#f38ba8
    '';
  };
}
