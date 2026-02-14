{ ... }:

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
    ./modules/system/users.nix

    # Programs
    ./modules/programs/development.nix
    ./modules/programs/terminal.nix
    ./modules/programs/browsers.nix
    ./modules/programs/media.nix
    ./modules/programs/wayland.nix
    ./modules/programs/system-tools.nix
    ./modules/programs/theming.nix

    # Desktop
    ./modules/desktop/hyprland.nix
    ./modules/desktop/fonts.nix

    # Services
    ./modules/services/services.nix

    # Home Manager
    <home-manager/nixos>
  ];

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ddudson = import ./home/home.nix;
  };
}
