{
  pkgs,
  ...
}:

{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    # Video & Audio
    vlc
    spotify

    # Communication
    discord

    # Media Tools
    aseprite
    ffmpeg
    imagemagick # Batch texture/sprite manipulation
    pavucontrol
    pamixer
    tiled # Tile map level editor

    # Document Tools
    poppler
  ];
}
