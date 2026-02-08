{ config, lib, pkgs, ... }:

{
  imports = [
    # Programs
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/nushell.nix
    ./programs/starship.nix
    ./programs/zoxide.nix
    ./programs/carapace.nix
    ./programs/rio.nix
    ./programs/zellij.nix
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
