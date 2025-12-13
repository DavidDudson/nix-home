{ config, lib, pkgs, ... }:

{
  imports = [
    # Programs
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/ghostty.nix
    ./programs/helix.nix

    # Desktop
    ./desktop/gtk.nix
    ./desktop/mako.nix
    ./desktop/hyprland.nix
    ./desktop/waybar.nix
    ./desktop/rofi.nix

    # MCP
    ./mcp/servers.nix
  ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";
}
