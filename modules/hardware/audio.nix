{ pkgs, ... }:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Let SOF firmware driver handle Intel Raptor Lake audio (00:1f.3)
  # while snd_hda_intel continues to handle NVIDIA HDMI (01:00.1)
  boot.extraModprobeConfig = ''
    options snd_hda_intel dmic_detect=0
    options snd-intel-dspcfg dsp_driver=3
  '';

  # pactl and other PulseAudio CLI tools
  environment.systemPackages = [ pkgs.pulseaudio ];
}
