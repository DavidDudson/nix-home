{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "David Dudson";
        email = "davidjohndudson@gmail.com";
      };
      aliases = {
        co = "checkout";
        ri = "rebase --interactive";
        logg = "log --graph";
        logo = "log --oneline";
        logs = "log --stat";
        logos = "log --oneline --stat";
        logogs = "log --oneline --graph --stat";
        shows = "show --stat";
        pick = "cherry-pick";
        amend = "commit -a --amend --no-edit";
      };
    };
  };
}
