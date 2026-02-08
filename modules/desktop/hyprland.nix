{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "start-hyprland";
        user = "ddudson";
      };
      default_session = initial_session;
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
