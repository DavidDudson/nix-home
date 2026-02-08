{ config, lib, pkgs, ... }:

{
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
