{ config, lib, pkgs, ... }:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "darcula";

      editor = {
        line-number = "relative";
        mouse = false;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };
      };
    };
  };
}
