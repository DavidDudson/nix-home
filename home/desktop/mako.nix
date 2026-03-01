{
  pkgs,
  ...
}:

{
  services.mako = {
    enable = true;

    settings = {
      # Appearance
      background-color = "#141414";
      text-color = "#fff3e0";
      border-color = "#ff9800";
      progress-color = "over #1a1a1a";

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
      border-color=#ff9800
      default-timeout=3000

      [urgency=normal]
      border-color=#ff9800
      default-timeout=5000

      [urgency=high]
      border-color=#ff5722
      default-timeout=0
      text-color=#ff5722
    '';
  };
}
