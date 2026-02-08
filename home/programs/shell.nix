{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_24  # Latest LTS
    uv  # For uvx to run Python MCP servers
  ];
}
