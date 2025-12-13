{ config, lib, pkgs, ... }:

{
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs.firefox.enable = true;

  users.defaultUserShell = pkgs.nushell;

  environment.systemPackages = with pkgs; [
    vim
    lshw
    wget
    kitty
    vlc
    vivaldi
    zed-editor
    curl
    git
    bat
    rofi
    nwg-look
    neofetch
    nixd
    jq
    fd
    procs
    sd
    hyprpicker
    hyprlock
    hypridle
    hyprpaper
    hyprshade
    hyprpolkitagent
    nil
    udiskie
    gh
    helix
    parted
    dust
    starship
    ripgrep
    chromium
    tokei
    nix-du
    pavucontrol
    pamixer
    bluez
    pipewire
    wireplumber
    ranger
    xdg-desktop-portal-hyprland
    cliphist
    wl-clipboard
    rio
    hyperfine
    bandwhich
    yazi
    jetbrains.rust-rover
    poppler
    ffmpeg
    mako
    zoxide
    resvg
    ghostty
    zellij
    waybar
    warp-terminal
    spotify
    code-cursor
    claude-code
    marksman
    taplo
    vscode-langservers-extracted
  ];
}
