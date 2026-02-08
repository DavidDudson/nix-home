{ config, lib, pkgs, ... }:

{
  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };
}
