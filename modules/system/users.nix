{ config, lib, pkgs, ... }:

{
  users.users.ddudson = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
