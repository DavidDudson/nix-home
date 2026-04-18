_:

{
  # Ensure matugen fallback colors exist before Hyprland sources them,
  # and deploy the Variety set_wallpaper hook as a real file (not a nix
  # store symlink) so Variety can chmod it during prepare_config_folder.
  home.activation.wallpaperSetup = ''
    [ -f "$HOME/.config/hypr/colors.conf" ] || cp "$HOME/.config/matugen/fallback/colors.conf" "$HOME/.config/hypr/colors.conf"
    [ -f "$HOME/.config/waybar/colors.css" ] || cp "$HOME/.config/matugen/fallback/colors.css" "$HOME/.config/waybar/colors.css"

    mkdir -p "$HOME/.config/variety/scripts"
    mkdir -p "$HOME/.config/variety/Downloaded"
    mkdir -p "$HOME/.config/variety/Fetched"
    mkdir -p "$HOME/.config/variety/Favorites"
    install -m 755 "${./set_wallpaper.sh}" "$HOME/.config/variety/scripts/set_wallpaper"
  '';

  home.file = {
    # Variety wallpaper changer config
    ".config/variety/variety.conf".source = ./variety.conf;

    # Local wallpapers (used as a Variety source)
    ".local/share/wallpapers".source = ./wallpapers;

    # Matugen color generation
    ".config/matugen/config.toml".source = ./matugen-config.toml;
    ".config/matugen/templates".source = ./templates;
    ".config/matugen/fallback/colors.conf".source = ./colors-fallback.conf;
    ".config/matugen/fallback/colors.css".source = ./colors-fallback.css;
  };
}
