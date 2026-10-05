{ pkgs, ... }:

let
  # Upstream release to track. ComfyUI ships roughly weekly; bump this tag
  # deliberately rather than floating `main` so a rebuild is reproducible.
  # The launcher checks the tag out and re-syncs the venv whenever it moves.
  comfyuiRef = "v0.31.1";

  # ComfyUI's README: "avoid python older than 3.12, 3.13 is very well
  # supported". Custom nodes increasingly assume 3.12+.
  python = pkgs.python313;

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
  # first run, then re-execs upstream main.py. Data lives in ~/ai/comfyui:
  # /home is 1.6 TB at 3% used while the root partition it used to live on
  # (/var/lib/comfyui) is under 200 GB and was hitting 85%. Model weights are
  # the fastest-growing thing here, so they belong on the big volume.
  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = with pkgs; [
      git
      python
      uv # resolves + installs the ~6 GB wheel set far faster than pip
    ];
    text = ''
      set -euo pipefail

      # See `torchLibs` above — PyPI torch dlopen's these at runtime.
      # /run/opengl-driver/lib is the NixOS-managed path for NVIDIA driver
      # libraries (libcuda.so.1, libnvidia-*). Without it torch reports
      # "Found no NVIDIA driver on your system" even though the kernel
      # module is loaded.
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:${pkgs.lib.makeLibraryPath torchLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      # Triton locates libcuda.so by shelling out to `/sbin/ldconfig -p`,
      # which does not exist on NixOS — models that hit a triton kernel
      # (Ideogram 4, torch.compile paths) die with FileNotFoundError deep
      # inside CLIPTextEncode. This env var is triton's documented escape.
      export TRITON_LIBCUDA_PATH="/run/opengl-driver/lib"

      ROOT="''${COMFYUI_ROOT:-$HOME/ai/comfyui}"
      REF="''${COMFYUI_REF:-${comfyuiRef}}"
      REPO="$ROOT/repo"
      VENV="$ROOT/venv"
      MODELS="$ROOT/models"
      STAMP="$ROOT/.venv-stamp"

      # /home is chronically near-full; keep uv's wheel cache on the root
      # partition next to the venv it feeds.
      export UV_CACHE_DIR="$ROOT/.uv-cache"

      # --base-directory relocates *every* folder_paths.py default under
      # $ROOT, including custom_nodes — which main.py os.listdir()s during
      # execute_prestartup_script() before any error handling. A missing
      # custom_nodes/ is therefore a hard crash loop, not a warning.
      mkdir -p "$MODELS" "$ROOT/custom_nodes" "$ROOT/input" "$ROOT/output" "$ROOT/user"

      # One-shot migration from the two previous data locations:
      # ~/.local/share/comfyui (pre-99ea272) and /var/lib/comfyui (the root
      # partition, abandoned once it passed 85% full). Only models/ and
      # output/ are worth moving — repo/ and venv/ rebuild themselves, and a
      # venv is not relocatable anyway.
      for legacy in "$HOME/.local/share/comfyui" /var/lib/comfyui; do
        [ "$legacy" = "$ROOT" ] && continue
        for kind in models output; do
          [ -d "$legacy/$kind" ] || continue
          echo "[comfyui] migrating $legacy/$kind → $ROOT/$kind"
          # Merge per subdirectory: a plain `mv models/loras $MODELS/` would
          # nest as models/loras/loras once the target subdir exists. mv -n
          # keeps whatever is already in the destination.
          find "$legacy/$kind" -mindepth 1 -maxdepth 1 -type d | while read -r sub; do
            mkdir -p "$ROOT/$kind/$(basename "$sub")"
            find "$sub" -mindepth 1 -maxdepth 1 -exec mv -n {} "$ROOT/$kind/$(basename "$sub")/" \;
            rmdir "$sub" 2>/dev/null || true
          done
          find "$legacy/$kind" -mindepth 1 -maxdepth 1 -type f -exec mv -n {} "$ROOT/$kind/" \;
          rmdir "$legacy/$kind" 2>/dev/null || true
        done
        rmdir "$legacy" 2>/dev/null || true
      done

      if [ ! -d "$REPO/.git" ]; then
        echo "[comfyui] cloning repo at $REF into $REPO"
        # Shallow, not blob-filtered: a --filter=blob:none clone makes every
        # checkout lazily fetch blobs, which turns a tag bump into a slow
        # network operation (and leaves a half-checked-out tree if it is
        # interrupted). Shallow clones fetch once and check out offline.
        git clone --depth 1 --branch "$REF" https://github.com/comfyanonymous/ComfyUI "$REPO"
      fi

      cd "$REPO"

      # Fetch the pinned tag only if we do not already have it, so a normal
      # start stays offline-safe.
      if ! git rev-parse -q --verify "refs/tags/$REF^{commit}" >/dev/null; then
        echo "[comfyui] fetching $REF"
        git fetch --depth 1 origin "refs/tags/$REF:refs/tags/$REF"
      fi
      if [ "$(git rev-parse HEAD)" != "$(git rev-parse "refs/tags/$REF^{commit}")" ]; then
        echo "[comfyui] checking out $REF"
        # -f because an interrupted checkout leaves a dirty tree that a plain
        # checkout refuses to touch, wedging every subsequent start.
        git checkout -q -f --detach "refs/tags/$REF"
      fi

      # Re-sync dependencies whenever the pinned release or the interpreter
      # moves. Without this the venv silently keeps whatever was resolved on
      # the day it was first created and drifts from requirements.txt.
      PYVER="$(${python}/bin/python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
      WANT="$REF|py$PYVER"
      if [ ! -x "$VENV/bin/python" ] || [ "$(cat "$STAMP" 2>/dev/null || true)" != "$WANT" ]; then
        if [ -x "$VENV/bin/python" ] &&
           [ "$("$VENV/bin/python" -c 'import sys; print("%d.%d" % sys.version_info[:2])')" != "$PYVER" ]; then
          echo "[comfyui] interpreter changed → rebuilding venv"
          rm -rf "$VENV"
        fi
        [ -x "$VENV/bin/python" ] || uv venv --python "${python}/bin/python3" "$VENV"

        # cu130 is what upstream asks for on 20-series and newer; the cu124
        # wheels this used to pin are two CUDA majors behind the 610.x driver.
        # unsafe-best-match lets uv consider both PyPI and the torch index for
        # the same package name (its default first-index strategy would not).
        echo "[comfyui] syncing python deps for $WANT"
        uv pip install --python "$VENV/bin/python" \
          --index-strategy unsafe-best-match \
          --extra-index-url https://download.pytorch.org/whl/cu130 \
          torch torchvision torchaudio
        uv pip install --python "$VENV/bin/python" -r "$REPO/requirements.txt"
        echo "$WANT" > "$STAMP"
      fi

      # --base-directory rewrites every default path in folder_paths.py to
      # sit under $ROOT, so models live at $MODELS (= $ROOT/models) and
      # ComfyUI actually discovers them. The previous COMFYUI_MODEL_DIR env
      # var was a no-op — ComfyUI doesn't read it, so models in
      # /var/lib/comfyui/models were silently ignored and only repo/models/
      # was scanned.
      exec "$VENV/bin/python" main.py \
        --listen 127.0.0.1 \
        --port 8188 \
        --base-directory "$ROOT" \
        --output-directory "$ROOT/output" \
        --preview-method auto \
        "$@"
    '';
  };
in
{
  home.packages = [ comfyui ];

  # Auto-start ComfyUI on graphical session. First boot does git clone +
  # dependency sync (~6 GB) so it can take several minutes; restart-on-failure
  # tolerates transient bootstrap errors. Listens on 127.0.0.1:8188.
  systemd.user.services.comfyui = {
    Unit = {
      Description = "ComfyUI Stable Diffusion UI";
      After = [
        "graphical-session.target"
        "network-online.target"
      ];
      Wants = [ "network-online.target" ];
      # A genuine config error (missing dir, bad tag) used to restart forever
      # at 10s intervals and only showed up as a silent 8188 connection
      # refused. Give up after 5 failures in 10 min so `systemctl --user
      # status comfyui` reports `failed` instead of `activating`.
      StartLimitIntervalSec = 600;
      StartLimitBurst = 5;
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
