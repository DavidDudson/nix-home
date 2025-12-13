{ config, lib, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal.enable = true;

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "Hyprland";
        user = "ddudson";
      };
      default_session = initial_session;
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
