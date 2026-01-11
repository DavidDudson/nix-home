{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_24  # Latest LTS
    uv  # For uvx to run Python MCP servers
  ];

  programs.nushell.extraConfig = ''
    let carapace_completer = {|spans|
       carapace $spans.0 nushell ...$spans | from json
    }
    $env.config = {
       show_banner: false,
       completions: {
         case_sensitive: false
         quick: true
         partial: true
         algorithm: "fuzzy"
         external: {
           enable: true
           max_results: 100
           completer: $carapace_completer
         }
       }
    }
    $env.PATH = ($env.PATH | split row (char esep) | prepend /home/ddudson/.apps | append /user/bin/env)
  '';

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.starship.enable = true;
}
