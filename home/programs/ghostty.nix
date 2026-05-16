_:

{
  programs.ghostty = {
    enable = true;

    settings = {
      font-family = "FiraCode Nerd Font";
      font-size = 14;

      window-decoration = "none";
      window-padding-x = 5;
      window-padding-y = 5;
      background-opacity = 0.95;
      background-blur-radius = 20;
      confirm-close-surface = false;

      cursor-style = "block";
      cursor-style-blink = false;

      mouse-scroll-multiplier = 3;

      # Vicinae orchis-dark palette
      background = "#141414";
      foreground = "#fff3e0";
      cursor-color = "#ff9800";
      selection-background = "#2a2a2a";
      selection-foreground = "#fff3e0";

      palette = [
        "0=#141414"
        "1=#ff5722"
        "2=#4caf50"
        "3=#ff6600"
        "4=#2196f3"
        "5=#e040fb"
        "6=#00bcd4"
        "7=#fff3e0"
        "8=#2a2a2a"
        "9=#ff8a65"
        "10=#81c784"
        "11=#ffab40"
        "12=#64b5f6"
        "13=#ea80fc"
        "14=#4dd0e1"
        "15=#ffffff"
      ];
    };
  };
}
