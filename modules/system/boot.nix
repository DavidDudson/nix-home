_:

{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
      edk2-uefi-shell.enable = true;
      windows."11".efiDeviceHandle = "FS1";
    };
    efi.canTouchEfiVariables = true;
  };

  boot.initrd.luks.devices.luksCrypted = {
    device = "/dev/disk/by-label/nixos-luks";
    preLVM = true;
    allowDiscards = true;
  };
}
