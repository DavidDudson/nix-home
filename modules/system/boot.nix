{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.systemd-boot.windows = {
    "11".efiDeviceHandle = "FS1";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd = {
    luks.devices = {
      luksCrypted = {
        device = "/dev/disk/by-label/nixos-luks";
        preLVM = true;
        allowDiscards = true;
      };
    };
  };
}
