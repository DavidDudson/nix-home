{ config, lib, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        border = 0;
        margin = 0;
        padding = 0;
        spacing = 0;

        bg = mkLiteral "#141414";
        bg-alt = mkLiteral "#1a1a1a";
        fg = mkLiteral "#fff3e0";
        orange = mkLiteral "#ff9800";
        orange-bright = mkLiteral "#ff6600";

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
      };

      window = {
        transparency = "real";
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        width = mkLiteral "600px";
        border = mkLiteral "2px";
        border-radius = mkLiteral "10px";
        border-color = mkLiteral "@orange";
        background-color = mkLiteral "@bg";
      };

      mainbox = {
        padding = mkLiteral "15px";
        background-color = mkLiteral "inherit";
        children = map mkLiteral [ "inputbar" "listview" ];
      };

      inputbar = {
        background-color = mkLiteral "@bg-alt";
        border-radius = mkLiteral "8px";
        padding = mkLiteral "8px 12px";
        margin = mkLiteral "0px 0px 15px 0px";
        children = map mkLiteral [ "prompt" "entry" ];
      };

      entry = {
        background-color = mkLiteral "transparent";
        padding = mkLiteral "8px 3px";
        text-color = mkLiteral "@fg";
        placeholder = "Search applications...";
        placeholder-color = mkLiteral "#ffffff44";
      };

      prompt = {
        background-color = mkLiteral "transparent";
        padding = mkLiteral "8px 12px 8px 0px";
        text-color = mkLiteral "@orange";
      };

      listview = {
        lines = 8;
        background-color = mkLiteral "transparent";
        spacing = mkLiteral "4px";
        scrollbar = false;
      };

      element = {
        padding = mkLiteral "8px 12px";
        border-radius = mkLiteral "6px";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
        children = map mkLiteral [ "element-icon" "element-text" ];
      };

      "element selected" = {
        background-color = mkLiteral "@bg-alt";
        border = mkLiteral "1px";
        border-color = mkLiteral "@orange";
        text-color = mkLiteral "@orange";
      };

      "element alternate" = {
        background-color = mkLiteral "transparent";
      };

      element-icon = {
        size = mkLiteral "24px";
        padding = mkLiteral "0px 12px 0px 0px";
        background-color = mkLiteral "transparent";
      };

      element-text = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };
    };

    extraConfig = {
      font = "FiraCode Nerd Font Medium 10";
      drun-display-name = "";
      run-display-name = "";
      window-display-name = "";
      timeout-delay = 10;
      timeout-action = "kb-cancel";
    };
  };

  # Copy the powermenu script
  home.file.".config/rofi/powermenu.sh" = {
    source = ../../files/rofi/powermenu.sh;
    executable = true;
  };
}
