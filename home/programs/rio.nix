{ config, lib, pkgs, ... }:

{
  programs.rio = {
    enable = true;

    settings = {
      cursor = {
        shape = "block";
        blinking = false;
      };

      editor = {
        program = "hx";
        args = [];
      };

      window = {
        decorations = "disabled";
        opacity = 0.95;
        padding = 5;
        blur = true;
      };

      fonts = {
        family = "FiraCode Nerd Font";
        size = 14;
      };

      colors = {
        background = "#282828";
        foreground = "#d0d0d0";
        cursor = "#d8d8d8";
        selection-background = "#383838";
        selection-foreground = "#f8f8f8";

        # Darcula color scheme
        black = "#181818";
        red = "#a34a27";
        green = "#629755";
        yellow = "#cc7832";
        blue = "#6897bb";
        magenta = "#9876aa";
        cyan = "#6897bb";
        white = "#d0d0d0";

        light-black = "#585858";
        light-red = "#cc7832";
        light-green = "#32cd32";
        light-yellow = "#eedd82";
        light-blue = "#104158";
        light-magenta = "#9876aa";
        light-cyan = "#6897bb";
        light-white = "#f8f8f8";
      };

      keyboard = {
        use-kitty-keyboard-protocol = true;
      };
    };
  };
}
