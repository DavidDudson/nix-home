_:

{
  imports = [
    # ComfyUI is entirely user-level now (home/local-ai/comfyui.nix); its data
    # moved off the root partition to ~/ai/comfyui, so the tmpfiles rule that
    # used to create /var/lib/comfyui is gone.
    ./ollama.nix
    ./open-webui.nix
  ];
}
