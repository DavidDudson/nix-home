{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Icon themes for notifications and apps
    papirus-icon-theme
  ];
}
