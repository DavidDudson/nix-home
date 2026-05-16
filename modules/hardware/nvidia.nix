{
  config,
  pkgs,
  ...
}:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # CUDA compute path. The display stack only needs nvidia/nvidia_modeset/
  # nvidia_drm; nvidia-uvm (Unified Memory) is what PyTorch and other CUDA
  # workloads dlopen at init time. Without it torch._C._cuda_init() fails
  # with "CUDA unknown error" and /dev/nvidia-uvm{,_tools} never appear.
  boot.kernelModules = [ "nvidia-uvm" ];
}
