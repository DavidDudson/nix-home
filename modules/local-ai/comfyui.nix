_:

{
  # ComfyUI's data lives on the root partition (60+ GB free) instead of
  # /home (chronically near-full). The home-manager comfyui launcher
  # defaults COMFYUI_ROOT to /var/lib/comfyui; this systemd-tmpfiles rule
  # creates the directory with the right owner so the user-level launcher
  # can write to it without sudo.
  systemd.tmpfiles.rules = [
    "d /var/lib/comfyui 0755 ddudson users -"
  ];
}
