{ pkgs, ... }:

let
  # Import mcp-servers-nix
  mcp-servers-nix = import (fetchTarball {
    url = "https://github.com/natsukium/mcp-servers-nix/archive/refs/heads/main.tar.gz";
  }) { inherit pkgs; };

  # Use fork of mcp-nixos with pytest 9.x fix
  mcp-nixos-fork = builtins.getFlake "github:DavidDudson/mcp-nixos/fix/pytest-toml-types";

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

      nixos = {
        enable = true;
        package = mcp-nixos-fork.packages.${pkgs.system}.mcp-nixos;
      };
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

  # HTTP MCP servers (not supported by mcp-servers-nix)
  httpServersConfig = {
    mcpServers = {
      pixellab = {
        type = "http";
        url = "https://api.pixellab.ai/mcp";
        headers = {
          Authorization = "Bearer \${PIXELLAB_API_KEY}";
        };
      };
    };
  };

  # Permission rules for Claude Code
  permissionsConfig = {
    permissions = {
      allow = [
        "Bash(sudo nixos-rebuild switch)"
        "Bash(sudo nixos-rebuild switch --upgrade)"
      ];
      deny = [
        "Bash(sudo *)"
      ];
    };
  };

  # Merge MCP config with statusLine
  mergedConfig =
    pkgs.runCommand "claude-settings.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        ${pkgs.jq}/bin/jq -s '.[0] * .[1] * .[2] * .[3]' \
          ${mcpConfig} \
          ${pkgs.writeText "statusline.json" (builtins.toJSON statusLineConfig)} \
          ${pkgs.writeText "http-servers.json" (builtins.toJSON httpServersConfig)} \
          ${pkgs.writeText "permissions.json" (builtins.toJSON permissionsConfig)} \
          > $out
      '';

in
{
  # Write the merged configuration to Claude Code settings
  home.file.".config/claude/settings.json".source = mergedConfig;
}
