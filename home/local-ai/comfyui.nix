{ pkgs, ... }:

let
  # ComfyUI is not packaged in nixpkgs. This launcher bootstraps a venv on
  # first run, then re-execs upstream main.py. Models live in
  # ~/.local/share/comfyui/models so they survive ComfyUI repo rewrites.
  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = with pkgs; [
      git
      python311
      stdenv.cc.cc.lib
    ];
    text = ''
      set -euo pipefail

      ROOT="''${COMFYUI_ROOT:-$HOME/.local/share/comfyui}"
      REPO="$ROOT/repo"
      VENV="$ROOT/venv"
      MODELS="$ROOT/models"

      mkdir -p "$ROOT" "$MODELS"

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
