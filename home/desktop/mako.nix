{ config, lib, pkgs, ... }:

{
  services.mako = {
    enable = true;

    # Appearance
    backgroundColor = "#1e1e2e";
    textColor = "#cdd6f4";
    borderColor = "#89b4fa";
    progressColor = "over #313244";

    # Layout
    width = 400;
    height = 150;
    margin = "20";
    padding = "15";
    borderSize = 2;
    borderRadius = 10;

    # Icons
    icons = true;
    maxIconSize = 64;
    iconPath = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";

    # Behavior
    defaultTimeout = 5000;
    ignoreTimeout = true;

    # Font
    font = "FiraCode Nerd Font 11";

    # Positioning
    anchor = "top-right";

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
