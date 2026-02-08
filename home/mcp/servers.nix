{ pkgs, ... }:

let
  # Import mcp-servers-nix
  mcp-servers-nix = import (fetchTarball {
    url = "https://github.com/natsukium/mcp-servers-nix/archive/refs/heads/main.tar.gz";
  }) { inherit pkgs; };

  # Build MCP server configuration
  mcpConfig = mcp-servers-nix.lib.mkConfig pkgs {
    format = "json";
    flavor = "claude-code";

    programs = {
      # Documentation and search
      context7.enable = true;

      # Development tools
      github.enable = true;
      git.enable = true;
      fetch.enable = true;
      time.enable = true;
      filesystem.enable = true;

      # AI capabilities
      memory.enable = true;
      sequential-thinking.enable = true;

      nixos.enable = true;
    };
  };

in
{
  # Write the generated MCP configuration to Claude Code settings
  home.file.".config/claude/settings.json".source = mcpConfig;
}
