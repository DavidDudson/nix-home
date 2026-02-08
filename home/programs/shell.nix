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
       color_config: {
         separator: "#585858"
         leading_trailing_space_bg: { fg: "#585858" }
         header: { fg: "#cc7832" attr: b }
         empty: "#585858"
         bool: "#6897bb"
         int: "#6897bb"
         float: "#6897bb"
         filesize: "#6897bb"
         duration: "#6897bb"
         datetime: "#6897bb"
         range: "#d0d0d0"
         string: "#629755"
         nothing: "#585858"
         binary: "#9876aa"
         cell-path: "#d0d0d0"
         record: "#d0d0d0"
         list: "#d0d0d0"
         block: "#d0d0d0"
         hints: "#585858"
         row_index: { fg: "#585858" attr: b }
         shape_block: { fg: "#cc7832" attr: b }
         shape_bool: "#6897bb"
         shape_custom: "#eedd82"
         shape_external: "#32cd32"
         shape_externalarg: "#d0d0d0"
         shape_filepath: "#629755"
         shape_flag: { fg: "#9876aa" attr: b }
         shape_float: "#6897bb"
         shape_garbage: { fg: "#f8f8f8" bg: "#a34a27" attr: b }
         shape_globpattern: { fg: "#cc7832" attr: b }
         shape_int: "#6897bb"
         shape_internalcall: { fg: "#eedd82" attr: b }
         shape_list: "#d0d0d0"
         shape_literal: "#6897bb"
         shape_nothing: "#585858"
         shape_operator: "#cc7832"
         shape_pipe: { fg: "#cc7832" attr: b }
         shape_range: { fg: "#cc7832" attr: b }
         shape_record: "#d0d0d0"
         shape_signature: { fg: "#eedd82" attr: b }
         shape_string: "#629755"
         shape_string_interpolation: { fg: "#629755" attr: b }
         shape_table: { fg: "#d0d0d0" attr: b }
         shape_variable: "#9876aa"
       }
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

  programs.starship = {
    enable = true;
    settings = {
      format = "[$directory$git_branch$git_status$character]()";
      directory = {
        style = "bold #cc7832";
        truncation_length = 3;
      };
      git_branch = {
        style = "#eedd82";
        format = "on [$symbol$branch]($style) ";
      };
      git_status = {
        style = "#629755";
      };
      character = {
        success_symbol = "[❯](#cc7832)";
        error_symbol = "[❯](#a34a27)";
      };
    };
  };
}
