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

  # Status line configuration for Claude Code
  statusLineConfig = {
    statusLine = {
      type = "command";
      command = "bun x ccusage statusline";
      padding = 0;
    };
  };

  # Merge MCP config with statusLine
  mergedConfig =
    pkgs.runCommand "claude-settings.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' ${mcpConfig} ${pkgs.writeText "statusline.json" (builtins.toJSON statusLineConfig)} > $out
      '';

in
{
  # Write the merged configuration to Claude Code settings
  home.file.".config/claude/settings.json".source = mergedConfig;
}
