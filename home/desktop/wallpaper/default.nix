_:

{
  # Ensure matugen output files exist before Hyprland sources them
  home.activation.matugenFallback = ''
    [ -f "$HOME/.config/hypr/colors.conf" ] || cp "$HOME/.config/matugen/fallback/colors.conf" "$HOME/.config/hypr/colors.conf"
    [ -f "$HOME/.config/waybar/colors.css" ] || cp "$HOME/.config/matugen/fallback/colors.css" "$HOME/.config/waybar/colors.css"
  '';

  home.file = {
    # Variety wallpaper changer config
    ".config/variety/variety.conf".source = ./variety.conf;
    ".config/variety/scripts/set_wallpaper" = {
      source = ./set_wallpaper.sh;
      executable = true;
    };

    # Local wallpapers (used as a Variety source)
    ".local/share/wallpapers".source = ./wallpapers;

    # Matugen color generation
    ".config/matugen/config.toml".source = ./matugen-config.toml;
    ".config/matugen/templates".source = ./templates;
    ".config/matugen/fallback/colors.conf".source = ./colors-fallback.conf;
    ".config/matugen/fallback/colors.css".source = ./colors-fallback.css;
  };
}
