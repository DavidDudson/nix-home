{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Video & Audio
    vlc
    spotify

    # Media Tools
    aseprite
    ffmpeg
    pavucontrol
    pamixer

    # Document Tools
    poppler
  ];
}
