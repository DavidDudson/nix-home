{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "David Dudson";
      user.email = "david.dudson@gmail.com";
    };
  };
}
