{ config, lib, pkgs, ... }:

{
  home.file.".config/ghostty/config".text = ''
    font-family = FiraCode Nerd Font
    window-decoration = false
    window-inherit-working-directory = true
    window-theme = dark
    window-save-state = always
    copy-on-select = true
    background = #282a36
    background-opacity = 0.7
    font-size = 11
    cursor-style = block
    foreground = #f8f8f2
    selection-foreground = #ffffff
    selection-background = #44475a
    cursor-color = #f8f8f2

    # Dracula color scheme
    palette = 0=#21222c
    palette = 1=#ff5555
    palette = 2=#50fa7b
    palette = 3=#f1fa8c
    palette = 4=#bd93f9
    palette = 5=#ff79c6
    palette = 6=#8be9fd
    palette = 7=#f8f8f2
    palette = 8=#6272a4
    palette = 9=#ff6e6e
    palette = 10=#69ff94
    palette = 11=#ffffa5
    palette = 12=#d6acff
    palette = 13=#ff92df
    palette = 14=#a4ffff
    palette = 15=#ffffff

    keybind = shift+enter=text:\x1b\r
  '';
}
