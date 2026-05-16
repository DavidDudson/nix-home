{ pkgs, lib, ... }:

let
  base = builtins.readFile ./variety-base.conf;

  mkProfileConf =
    theme:
    pkgs.writeText "variety-${theme}.conf" ''
      ${base}
      ${builtins.readFile (./themes + "/${theme}.conf")}
    '';

  themes = [
    "landscapes"
    "space"
    "anime"
    "cyberpunk"
    "minimal"
  ];

  # Activation lines that copy each theme's generated variety.conf into
  # the live profile dir as a writable real file (not a nix-store symlink).
  # Variety writes back to variety.conf on its own (download dirs, etc.)
  # and variety-theme.sh injects the Wallhaven API key into it — both
  # require a mutable file. Activation reruns every switch, so any nix
  # template changes propagate; the API-key line is re-injected by
  # variety-theme.sh at next session start.
  themeInstallLines = lib.concatStringsSep "\n" (
    map (theme: ''
      install -D -m 644 "${mkProfileConf theme}" "$HOME/.config/variety-profiles/${theme}/variety.conf"
    '') themes
  );
in
{
  # Seed matugen outputs with fallback content so Hyprland / Waybar / Mako
  # can source colors before the first wallpaper change. Use install -m 644
  # instead of cp so the nix-store source's read-only perms don't leak
  # through and block matugen from overwriting these files later. Also
  # deploy the Variety set_wallpaper hook and the theme switcher as real
  # executables in ~/.local/bin so Variety and waybar can invoke them.
  home.activation.wallpaperSetup = ''
    for pair in \
      "hypr/colors.lua:colors.lua" \
      "waybar/colors.css:colors.css" \
      "mako/config:mako-config"
    do
      dest="$HOME/.config/''${pair%%:*}"
      src="$HOME/.config/matugen/fallback/''${pair##*:}"
      if [ ! -f "$dest" ] || [ ! -w "$dest" ]; then
        install -D -m 644 "$src" "$dest"
      fi
    done
    # Remove legacy hyprlang colors.conf (replaced by colors.lua)
    rm -f "$HOME/.config/hypr/colors.conf" || true

    install -D -m 755 "${./set_wallpaper.sh}" "$HOME/.local/bin/variety-set-wallpaper"
    install -D -m 755 "${./variety-theme.sh}" "$HOME/.local/bin/variety-theme"

    ${themeInstallLines}
  '';

  home.file = {
    # Local wallpapers (used as a Variety source)
    ".local/share/wallpapers".source = ./wallpapers;

    # Matugen color generation. Templates are placed individually (not via
    # a whole-directory source) so mako.nix can contribute its own template
    # that needs nix-time substitution of the papirus icon path.
    ".config/matugen/config.toml".source = ./matugen-config.toml;
    ".config/matugen/templates/hyprland-colors.lua".source = ./templates/hyprland-colors.lua;
    ".config/matugen/templates/waybar-colors.css".source = ./templates/waybar-colors.css;
    ".config/matugen/fallback/colors.lua".source = ./colors-fallback.lua;
    ".config/matugen/fallback/colors.css".source = ./colors-fallback.css;
  };
}
