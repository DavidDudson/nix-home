{ pkgs, ... }:

let
  # PyPI's torch wheel is a manylinux binary that dlopen's libstdc++.so.6
  # (and friends) at runtime by walking LD_LIBRARY_PATH. NixOS has none of
  # those libs at /usr/lib, so the venv'd python import fails with
  # `libstdc++.so.6: cannot open shared object file`. Inject the lib paths
  # explicitly. zlib / libGL / glib / libxcrypt are the other usual suspects
  # for torch + pillow + opencv extras.
  torchLibs = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libGL
    glib
    libxcrypt-legacy
  ];

  # ComfyUI is not packaged in nixpkgs. This launcher bootstraps a venv on
  # first run, then re-execs upstream main.py. Data lives in
  # /var/lib/comfyui (root partition has more headroom than /home for the
  # torch+CUDA wheels and model checkpoints). The directory is created and
  # chowned by the host module (modules/local-ai/comfyui.nix).
  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = with pkgs; [
      git
      python311
    ];
    text = ''
      set -euo pipefail

      # See `torchLibs` above — PyPI torch dlopen's these at runtime.
      # /run/opengl-driver/lib is the NixOS-managed path for NVIDIA driver
      # libraries (libcuda.so.1, libnvidia-*). Without it torch reports
      # "Found no NVIDIA driver on your system" even though the kernel
      # module is loaded.
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:${pkgs.lib.makeLibraryPath torchLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      ROOT="''${COMFYUI_ROOT:-/var/lib/comfyui}"
      REPO="$ROOT/repo"
      VENV="$ROOT/venv"
      MODELS="$ROOT/models"

      mkdir -p "$ROOT" "$MODELS"

      # One-shot migration from the legacy ~/.local/share/comfyui location
      # (used before the relocation to /var/lib/comfyui in 99ea272).
      legacy="$HOME/.local/share/comfyui"
      if [ -d "$legacy/models" ] && [ "$legacy" != "$ROOT" ]; then
        echo "[comfyui] migrating models from $legacy/models → $MODELS"
        # mv is cross-filesystem (/home → /); copies bytes then removes source.
        find "$legacy/models" -mindepth 1 -maxdepth 1 -exec mv {} "$MODELS/" \;
        rmdir "$legacy/models" 2>/dev/null || true
        rmdir "$legacy" 2>/dev/null || true
      fi

      if [ ! -d "$REPO/.git" ]; then
        echo "[comfyui] cloning repo into $REPO"
        git clone --depth 1 https://github.com/comfyanonymous/ComfyUI "$REPO"
      fi

      if [ ! -d "$VENV" ]; then
        echo "[comfyui] creating venv at $VENV"
        python3 -m venv "$VENV"
        # shellcheck disable=SC1091
        source "$VENV/bin/activate"
        pip install --upgrade pip wheel
        pip install --extra-index-url https://download.pytorch.org/whl/cu124 \
          torch torchvision torchaudio
        pip install -r "$REPO/requirements.txt"
      else
        # shellcheck disable=SC1091
        source "$VENV/bin/activate"
      fi

      # Point ComfyUI at the persistent models dir.
      export COMFYUI_MODEL_DIR="$MODELS"

      cd "$REPO"
      exec python main.py \
        --listen 127.0.0.1 \
        --port 8188 \
        --output-directory "$ROOT/output" \
        "$@"
    '';
  };
in
{
  home.packages = [ comfyui ];

  # Auto-start ComfyUI on graphical session. First boot does git clone +
  # pip install (~3 GB) so it can take several minutes; restart-on-failure
  # tolerates transient bootstrap errors. Listens on 127.0.0.1:8188.
  systemd.user.services.comfyui = {
    Unit = {
      Description = "ComfyUI Stable Diffusion UI";
      After = [
        "graphical-session.target"
        "network-online.target"
      ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${comfyui}/bin/comfyui";
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
