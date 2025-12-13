{ config, lib, pkgs, ... }:

{
  imports = [
    ./programs/git.nix
    ./programs/shell.nix
    ./desktop/gtk.nix
    ./desktop/mako.nix
    ./mcp/servers.nix
  ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";
}
