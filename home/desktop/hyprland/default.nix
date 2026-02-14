{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  home.file = {
    ".config/hypr/appearance.conf".source = ./appearance.conf;
    ".config/hypr/input.conf".source = ./input.conf;
    ".config/hypr/keybindings.conf".source = ./keybindings.conf;
    ".config/hypr/rules.conf".source = ./rules.conf;
    ".config/hypr/hyprpaper.conf".source = ./hyprpaper.conf;
  };
}
