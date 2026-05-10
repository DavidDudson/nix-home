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

      background = "#282828";
      foreground = "#d0d0d0";
      cursor-color = "#d8d8d8";
      selection-background = "#383838";
      selection-foreground = "#f8f8f8";

      palette = [
        "0=#181818"
        "1=#a34a27"
        "2=#629755"
        "3=#cc7832"
        "4=#6897bb"
        "5=#9876aa"
        "6=#6897bb"
        "7=#d0d0d0"
        "8=#585858"
        "9=#cc7832"
        "10=#32cd32"
        "11=#eedd82"
        "12=#104158"
        "13=#9876aa"
        "14=#6897bb"
        "15=#f8f8f8"
      ];
    };
  };
}
