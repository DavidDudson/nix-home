_:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
        edk2-uefi-shell.enable = true;
        windows."11".efiDeviceHandle = "FS1";
      };
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      # systemd initrd (the only kind now) lets LUKS auto-unlock via TPM2
      # (enrolled with systemd-cryptenroll)
      luks.devices.luksCrypted = {
        device = "/dev/disk/by-label/nixos-luks";
        allowDiscards = true;
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      };
    };
  };
}
