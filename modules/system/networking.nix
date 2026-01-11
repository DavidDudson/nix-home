{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "DavidDudsonPC";
    networkmanager.enable = true;
  };

  services.openssh.enable = true;
}
