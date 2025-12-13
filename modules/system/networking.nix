{ config, lib, pkgs, ... }:

{
  networking.hostName = "DavidDudsonPC";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
}
