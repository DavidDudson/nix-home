{ config, lib, pkgs, ... }:

{
  imports = [
    # Hardware
    /etc/nixos/hardware-configuration.nix
    ./modules/hardware/nvidia.nix
    ./modules/hardware/bluetooth.nix
    ./modules/hardware/audio.nix

    # System
    ./modules/system/boot.nix
    ./modules/system/networking.nix
    ./modules/system/nix.nix
    ./modules/system/programs.nix
    ./modules/system/users.nix

    # Desktop
    ./modules/desktop/hyprland.nix
    ./modules/desktop/fonts.nix

    # Services
    ./modules/services/services.nix

    # Home Manager
    <home-manager/nixos>
  ];

  # Home Manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.ddudson = import ./home/home.nix;
}
