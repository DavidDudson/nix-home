{ config, lib, pkgs, ... }:

{
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };
}
