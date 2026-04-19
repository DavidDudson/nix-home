{
  pkgs,
  ...
}:

let
  papirusIconPath = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";

  substituteIconPath =
    src:
    pkgs.runCommand "${baseNameOf src}" { } ''
      substitute ${src} $out --subst-var-by papirusIconPath ${papirusIconPath}
    '';
in
{
  # mako is started via its systemd user service, but this module no longer
  # writes ~/.config/mako/config — matugen owns that file so wallpaper-driven
  # colors can be refreshed live. A fallback config is seeded on first
  # activation (see home/desktop/wallpaper/default.nix).
  services.mako.enable = true;

  home.file.".config/matugen/templates/mako-config".source =
    substituteIconPath ./wallpaper/templates/mako-config;
  home.file.".config/matugen/fallback/mako-config".source =
    substituteIconPath ./wallpaper/mako-fallback.conf;
}
