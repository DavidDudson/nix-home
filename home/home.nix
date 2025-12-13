{ config, lib, pkgs, ... }:

{
  imports = [
    ./programs/git.nix
    ./programs/shell.nix
    ./desktop/gtk.nix
    ./mcp/servers.nix
  ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";
}
