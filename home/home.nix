{
  ...
}:

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

  home = {
    enableNixpkgsReleaseCheck = false;
    stateVersion = "24.11";

    file.".claude/CLAUDE.md".text = ''
      # Global Instructions

      ## Security

      - NEVER commit secrets, API keys, tokens, passwords, or other sensitive information to any repository.
      - If you encounter or are about to write sensitive values, stop and confirm with the user before proceeding.
      - Use environment variables, secret managers (1Password CLI, agenix, sops-nix), or `.gitignore`d files for secrets.

      ## Communication Style

      - Treat the user as an expert. Keep answers simple and concise.
      - The user does not always suggest the best option and can get things wrong. Respectfully push back when you see a better approach.
      - Always ask follow-up questions when requirements are ambiguous rather than assuming.
      - During planning, confirm you have all relevant information before proceeding with implementation.
    '';
  };
}
