{ config, lib, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;

    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        border = 0;
        margin = 0;
        padding = 0;
        spacing = 0;

        bg = mkLiteral "#000000";
        fg = mkLiteral "#f8f8f2";
        orange = mkLiteral "#ff9800";

        background-color = mkLiteral "@bg";
        text-color = mkLiteral "@fg";
        border-color = mkLiteral "@orange";
      };

      window = {
        transparency = "real";
      };

      mainbox = {
        children = map mkLiteral [ "inputbar" "listview" ];
      };

      inputbar = {
        background-color = mkLiteral "@bg";
        text-color = mkLiteral "@orange";
        children = map mkLiteral [ "prompt" "entry" ];
      };

      entry = {
        background-color = mkLiteral "inherit";
        padding = mkLiteral "12px 3px";
        text-color = mkLiteral "@orange";
      };

      prompt = {
        background-color = mkLiteral "inherit";
        padding = mkLiteral "12px";
        text-color = mkLiteral "@orange";
      };

      listview = {
        lines = 8;
      };

      element = {
        children = map mkLiteral [ "element-icon" "element-text" ];
        text-color = mkLiteral "@orange";
      };

      element-icon = {
        padding = mkLiteral "10px 10px";
      };

      element-text = {
        padding = mkLiteral "10px 0";
        text-color = mkLiteral "inherit";
      };

      "element-text selected" = {
        text-color = mkLiteral "@orange";
      };
    };

    extraConfig = {
      font = "FiraCode Nerd Font Medium 10";
      drun-display-name = "";
      run-display-name = "";
      window-display-name = "";
      timeout = {
        delay = 10;
        action = "kb-cancel";
      };
    };
  };

  # Copy the powermenu script
  home.file.".config/rofi/powermenu.sh" = {
    source = /home/ddudson/.config/rofi/powermenu.sh;
    executable = true;
  };
}
