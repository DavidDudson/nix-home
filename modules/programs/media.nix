{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Video & Audio
    vlc
    spotify

    # Media Tools
    ffmpeg
    pavucontrol
    pamixer

    # Document Tools
    poppler
  ];
}
