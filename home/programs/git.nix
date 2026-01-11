{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name = "David Dudson";
      email = "david.dudson@gmail.com";
    };
  };
}
