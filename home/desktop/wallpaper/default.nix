_:

{
  # Seed matugen outputs with fallback content so Hyprland / Waybar / Mako
  # can source colors before the first wallpaper change. Use install -m 644
  # instead of cp so the nix-store source's read-only perms don't leak
  # through and block matugen from overwriting these files later. Also
  # deploy the Variety set_wallpaper hook as a real file (not a nix store
  # symlink) so Variety can chmod it during prepare_config_folder.
  home.activation.wallpaperSetup = ''
    for pair in \
      "hypr/colors.conf:colors.conf" \
      "waybar/colors.css:colors.css" \
      "mako/config:mako-config"
    do
      dest="$HOME/.config/''${pair%%:*}"
      src="$HOME/.config/matugen/fallback/''${pair##*:}"
      if [ ! -f "$dest" ] || [ ! -w "$dest" ]; then
        install -D -m 644 "$src" "$dest"
      fi
    done

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

    # Matugen color generation. Templates are placed individually (not via
    # a whole-directory source) so mako.nix can contribute its own template
    # that needs nix-time substitution of the papirus icon path.
    ".config/matugen/config.toml".source = ./matugen-config.toml;
    ".config/matugen/templates/hyprland-colors.conf".source = ./templates/hyprland-colors.conf;
    ".config/matugen/templates/waybar-colors.css".source = ./templates/waybar-colors.css;
    ".config/matugen/fallback/colors.conf".source = ./colors-fallback.conf;
    ".config/matugen/fallback/colors.css".source = ./colors-fallback.css;
  };
}
