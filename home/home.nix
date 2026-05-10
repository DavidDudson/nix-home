{
  ...
}:

{
  imports = [
    # Programs
    ./programs/git
    ./programs/shell.nix
    ./programs/nushell
    ./programs/starship.nix
    ./programs/zoxide.nix
    ./programs/carapace.nix
    ./programs/direnv.nix
    ./programs/ghostty.nix
    ./programs/claude-popout.nix
    ./programs/zellij
    ./programs/helix.nix
    ./programs/zed
    ./programs/yazi.nix
    ./programs/secrets

    # Desktop
    ./desktop/gtk.nix
    ./desktop/mako.nix
    ./desktop/hyprland
    ./desktop/hypridle
    ./desktop/waybar
    ./desktop/vicinae.nix
    ./desktop/wallpaper
    ./desktop/termfilechooser.nix

    # MCP
    ./mcp/servers.nix

    # Local AI (ComfyUI + CLI tools)
    ./local-ai
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    stateVersion = "24.11";

    file = {
      ".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
      ".claude/statusline.sh" = {
        source = ./claude/statusline.sh;
        executable = true;
      };
      ".claude/skills/nixos-upgrade-summary/SKILL.md".source =
        ./claude/skills/nixos-upgrade-summary/SKILL.md;
    };
  };
}
