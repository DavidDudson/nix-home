{ config, lib, pkgs, ... }:

{
  home.file.".config/ghostty/config".text = ''
    font-family = FiraCode Nerd Font
    window-decoration = false
    window-inherit-working-directory = true
    window-theme = dark
    window-save-state = always
    copy-on-select = true
    background = #282828
    background-opacity = 0.7
    font-size = 11
    cursor-style = block
    foreground = #d0d0d0
    selection-foreground = #f8f8f8
    selection-background = #383838
    cursor-color = #d8d8d8

    # Darcula color scheme
    palette = 0=#181818
    palette = 1=#a34a27
    palette = 2=#629755
    palette = 3=#cc7832
    palette = 4=#6897bb
    palette = 5=#9876aa
    palette = 6=#6897bb
    palette = 7=#d0d0d0
    palette = 8=#585858
    palette = 9=#cc7832
    palette = 10=#32cd32
    palette = 11=#eedd82
    palette = 12=#104158
    palette = 13=#9876aa
    palette = 14=#6897bb
    palette = 15=#f8f8f8

    keybind = shift+enter=text:\x1b\r
  '';
}
