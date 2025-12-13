{ config, lib, pkgs, ... }:

{
  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  environment.systemPackages = with pkgs; [
    # System Utilities
    neofetch
    udiskie      # Automount removable media

    # Audio/Video Backend
    bluez
    pipewire
    wireplumber
  ];
}
