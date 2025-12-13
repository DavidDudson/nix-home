{ config, lib, pkgs, ... }:

{
  # Claude Code MCP server configuration
  home.file.".config/claude/settings.json".text = builtins.toJSON {
    mcpServers = {
      context7 = {
        command = "${pkgs.nodejs_20}/bin/npx";
        args = [ "-y" "@upstash/context7-mcp" ];
        transport = "stdio";
      };
      github = {
        command = "${pkgs.nodejs_20}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-github" ];
        transport = "stdio";
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
        transport = "stdio";
      };
    };
  };
}
