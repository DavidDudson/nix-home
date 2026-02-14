{
  ...
}:

{
  imports = [
    # Programs
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/nushell
    ./programs/starship.nix
    ./programs/zoxide.nix
    ./programs/carapace.nix
    ./programs/rio.nix
    ./programs/zellij
    ./programs/helix.nix
    ./programs/zed
    ./programs/yazi.nix

    # Desktop
    ./desktop/gtk.nix
    ./desktop/mako.nix
    ./desktop/hyprland
    ./desktop/waybar.nix
    ./desktop/rofi
    ./desktop/termfilechooser.nix

    # MCP
    ./mcp/servers.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    stateVersion = "24.11";

    file.".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
  };
}
