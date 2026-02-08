{ config, lib, pkgs, ... }:

let
  termfilechooser = pkgs.xdg-desktop-portal-termfilechooser;
in
{
  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=${termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
    default_dir=$HOME
    env=TERMCMD=rio -e
    open_mode=suggested
    save_mode=suggested
  '';
}
