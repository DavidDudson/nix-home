{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/dbe0ae6f-6d5f-4bb1-8970-0e0cb97991ca";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2358-579A";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/d5df1e71-e1ad-4bf8-846e-bb51b4dbe927";
      fsType = "ext4";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/e0780a30-321e-42f3-904e-427b1ca3f277"; }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
