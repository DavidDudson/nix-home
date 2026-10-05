{ pkgs, ... }:

let
  # ai-toolkit has no release tags; pin a commit so a rebuild is reproducible.
  aiToolkitRev = "3a28c4b1b7177ae2567f6b5b8af2f7f7284bf557";

  # 3.12, not ComfyUI's 3.13: ai-toolkit pins scipy==1.12.0, which has no
  # cp313 wheel, so 3.13 tries to build it from source and dies looking for a
  # Fortran compiler. 3.12 installs prebuilt.
  python = pkgs.python312;

  # Same runtime library injection as the ComfyUI launcher: PyPI torch wheels
  # dlopen libstdc++ and friends, and libcuda lives under /run/opengl-driver.
  torchLibs = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libGL
    glib
    libxcrypt-legacy
  ];

  commonEnv = ''
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${pkgs.lib.makeLibraryPath torchLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export TRITON_LIBCUDA_PATH="/run/opengl-driver/lib"
    AI_ROOT="''${AI_ROOT:-$HOME/ai}"
    export UV_CACHE_DIR="$AI_ROOT/comfyui/.uv-cache"
    # Base weights are big; keep them off the small root partition.
    export HF_HOME="''${HF_HOME:-$AI_ROOT/hf-cache}"
  '';

  # Captions matter more than image count for a style LoRA: the model learns
  # "this look" from what the captions *don't* say. qwen3-vl runs locally, so
  # captioning 60 images costs nothing but GPU minutes.
  lora-caption = pkgs.writeShellApplication {
    name = "lora-caption";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = ''
      set -euo pipefail

      DATASET="''${1:?usage: lora-caption <dataset-dir> [trigger-word]}"
      TRIGGER="''${2:-}"
      OLLAMA="''${OLLAMA_URL:-http://127.0.0.1:11434}"
      MODEL="''${CAPTION_MODEL:-qwen3-vl:8b}"

      shopt -s nullglob nocaseglob
      for img in "$DATASET"/*.{png,jpg,jpeg,webp}; do
        txt="''${img%.*}.txt"
        [ -f "$txt" ] && { echo "[caption] skip $(basename "$img") (already captioned)"; continue; }

        # A 1 MP png is ~1.5 MB of base64 — past ARG_MAX, so it goes through
        # files rather than argv on both the jq and curl side.
        tmp="$(mktemp -d)"
        base64 -w0 "$img" > "$tmp/img.b64"
        # Describe subject and composition but NOT the art style: the trigger
        # word has to absorb the style, so naming it in captions teaches the
        # LoRA to depend on those words instead.
        prompt="Describe this image in one sentence for an image-generation caption. State the subject, pose, and composition. Do not describe the art style, colour palette, or medium. No preamble."
        jq -n --arg m "$MODEL" --arg p "$prompt" --rawfile i "$tmp/img.b64" \
          '{model:$m, stream:false, messages:[{role:"user", content:$p, images:[$i]}]}' \
          > "$tmp/payload.json"
        caption="$(curl -sS "$OLLAMA/api/chat" --data-binary "@$tmp/payload.json" | jq -r '.message.content')"
        rm -rf "$tmp"

        if [ -n "$TRIGGER" ]; then
          caption="$TRIGGER, $caption"
        fi
        printf '%s\n' "$caption" > "$txt"
        echo "[caption] $(basename "$img"): $caption"
      done
    '';
  };

  lora-train = pkgs.writeShellApplication {
    name = "lora-train";
    runtimeInputs = with pkgs; [
      git
      python
      uv
      gnused
      coreutils
      systemd # systemctl, to yield the GPU by stopping comfyui
    ];
    text = ''
      set -euo pipefail
      ${commonEnv}

      NAME="''${1:?usage: lora-train <name> <dataset-dir> [steps] [trigger-word]}"
      DATASET="''${2:?usage: lora-train <name> <dataset-dir> [steps] [trigger-word]}"
      STEPS="''${3:-2000}"
      TRIGGER="''${4:-$NAME}"

      # One GPU, two greedy tenants: ComfyUI keeps its last model resident, so
      # training starts into ~10 GB of free VRAM and OOMs partway through.
      # Stop it for the duration and put it back afterwards.
      COMFY_WAS_RUNNING=0
      if systemctl --user is-active --quiet comfyui; then
        echo "[lora-train] stopping comfyui to free VRAM"
        systemctl --user stop comfyui
        COMFY_WAS_RUNNING=1
      fi
      restore_comfyui() {
        if [ "$COMFY_WAS_RUNNING" = 1 ]; then
          echo "[lora-train] restarting comfyui"
          systemctl --user start comfyui || true
        fi
      }
      trap restore_comfyui EXIT

      # Long training runs fragment the allocator; expandable segments keep the
      # tail end of a run from failing on a 20 MB allocation.
      export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

      DATASET="$(realpath "$DATASET")"
      REPO="$AI_ROOT/ai-toolkit"
      VENV="$REPO/venv"
      OUTPUT="$AI_ROOT/lora-output"
      STAMP="$REPO/.venv-stamp"

      count=$(find "$DATASET" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | wc -l)
      if [ "$count" -lt 5 ]; then
        echo "[lora-train] $DATASET has $count images; need at least 5 (30-120 is the useful range)" >&2
        exit 1
      fi
      echo "[lora-train] $count images, $STEPS steps, trigger '$TRIGGER'"

      mkdir -p "$OUTPUT" "$HF_HOME"

      if [ ! -d "$REPO/.git" ]; then
        echo "[lora-train] cloning ai-toolkit into $REPO"
        git clone https://github.com/ostris/ai-toolkit "$REPO"
      fi
      cd "$REPO"
      if [ "$(git rev-parse HEAD)" != "${aiToolkitRev}" ]; then
        git fetch origin ${aiToolkitRev}
        git checkout -q -f --detach ${aiToolkitRev}
      fi

      PYVER="$(${python}/bin/python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
      WANT="${aiToolkitRev}|py$PYVER"
      if [ ! -x "$VENV/bin/python" ] || [ "$(cat "$STAMP" 2>/dev/null || true)" != "$WANT" ]; then
        [ -x "$VENV/bin/python" ] || uv venv --python "${python}/bin/python3" "$VENV"
        echo "[lora-train] syncing deps for $WANT"
        # Versions taken from ai-toolkit's README; the cu130 index matches the
        # ComfyUI venv so the cached wheels are reused rather than refetched.
        uv pip install --python "$VENV/bin/python" \
          --index-strategy unsafe-best-match \
          --extra-index-url https://download.pytorch.org/whl/cu130 \
          torch==2.13.0 torchvision==0.28.0 torchaudio==2.11.0
        uv pip install --python "$VENV/bin/python" -r "$REPO/requirements.txt"
        echo "$WANT" > "$STAMP"
      fi

      CONFIG="$OUTPUT/$NAME.yaml"
      sed -e "s|@NAME@|$NAME|g" \
          -e "s|@DATASET@|$DATASET|g" \
          -e "s|@OUTPUT@|$OUTPUT|g" \
          -e "s|@TRIGGER@|$TRIGGER|g" \
          -e "s|@STEPS@|$STEPS|g" \
          ${./zimage-lora.yaml.in} > "$CONFIG"
      echo "[lora-train] config written to $CONFIG"

      "$VENV/bin/python" run.py "$CONFIG"

      # Drop the finished LoRA where ComfyUI (and so the gameart MCP) sees it.
      LORAS="$AI_ROOT/comfyui/models/loras"
      if [ -d "$LORAS" ]; then
        latest="$(find "$OUTPUT/$NAME" -maxdepth 1 -name '*.safetensors' | sort | tail -1)"
        if [ -n "$latest" ]; then
          cp -f "$latest" "$LORAS/$NAME.safetensors"
          echo "[lora-train] installed $LORAS/$NAME.safetensors"
        fi
      fi
    '';
  };
in
{
  home.packages = [
    lora-caption
    lora-train
  ];
}
