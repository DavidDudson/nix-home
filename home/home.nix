{ config, lib, pkgs, ... }:

{
  imports = [
    # Programs
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/ghostty.nix
    ./programs/helix.nix
    ./programs/zed.nix
    ./programs/yazi.nix

    # Desktop
    ./desktop/gtk.nix
    ./desktop/mako.nix
    ./desktop/hyprland.nix
    ./desktop/waybar.nix
    ./desktop/rofi.nix
    ./desktop/termfilechooser.nix

    # MCP
    ./mcp/servers.nix
  ];
  
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";
}
