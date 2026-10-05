{
  config,
  pkgs,
  ...
}:

let
  extensionsRepo = pkgs.fetchFromGitHub {
    owner = "vicinaehq";
    repo = "extensions";
    rev = "def646b3655e13759d2b0a7b9d605f55fe83a5f7";
    hash = "sha256-xG2Nvdhl+lcguYzkAHf6RkHQpM8c3rbN0NDHUiwT4CA=";
  };
  mkExt =
    name:
    config.lib.vicinae.mkExtension {
      inherit name;
      src = extensionsRepo + "/extensions/${name}";
    };

  # Builder for extensions with optional native deps that fail under node-gyp.
  # Passes --ignore-scripts so install scripts for optional native modules —
  # currently usocket, which node-gyp 7.1.2 cannot build against node 24 — are
  # skipped rather than run.
  mkNativeExt =
    name:
    let
      src = extensionsRepo + "/extensions/${name}";
    in
    pkgs.buildNpmPackage {
      inherit name src;
      npmFlags = [ "--ignore-scripts" ];
      # usocket's index.js does require('debug') without declaring debug as a
      # dependency, so esbuild cannot resolve it in trees that do not happen to
      # hoist debug for another reason. A no-op stub is enough: --ignore-scripts
      # leaves usocket's native binding uncompiled, so require('usocket')
      # throws at runtime and dbus-next falls back to net.createConnection
      # (lib/connection.js). Adding debug to the lockfile instead would break
      # importNpmLock's offline cache with ENOTCACHED.
      preBuild = ''
        if [ -d node_modules/usocket ] && [ ! -d node_modules/debug ]; then
          mkdir -p node_modules/debug
          echo '{"name":"debug","version":"0.0.0-stub","main":"index.js"}' \
            > node_modules/debug/package.json
          echo 'module.exports = function () { return function () {}; };' \
            > node_modules/debug/index.js
        fi
      '';
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r /build/.local/share/vicinae/extensions/${name}/* $out/
        runHook postInstall
      '';
      npmDeps = pkgs.importNpmLock { npmRoot = src; };
      inherit (pkgs.importNpmLock) npmConfigHook;
    };
in
{
  programs.vicinae = {
    enable = true;
    useLayerShell = true;

    systemd = {
      enable = true;
      autoStart = true;
      target = "hyprland-session.target";
    };

    extensions =
      map mkExt [
        "color-converter"
        "fuzzy-files"
        "github"
        "hypr-keybinds"
        "hyprland-monitors"
        "it-tools"
        "nix"
        "player-pilot"
        "port-killer"
        "process-manager"
        "pulseaudio"
        "ssh"
      ]
      ++ [
        # Both pull the optional native usocket module via package-lock.json
        (mkNativeExt "bluetooth")
        (mkNativeExt "systemd")
      ];

    settings = {
      font = {
        family = "FiraCode Nerd Font";
        size = 13;
      };
      theme = {
        name = "orchis-dark";
      };
      window = {
        csd = false;
        opacity = 0.95;
        rounding = 10;
      };
      popToRootOnClose = true;
      closeOnFocusLoss = true;
    };

    themes.orchis-dark = {
      meta = {
        version = 1;
        name = "Orchis Dark";
        description = "Dark theme matching Orchis-Dark-Compact system theme";
        variant = "dark";
        inherits = "vicinae-dark";
      };

      colors = {
        core = {
          background = "#141414";
          foreground = "#fff3e0";
          secondary_background = "#1a1a1a";
          border = "#2a2a2a";
          accent = "#ff9800";
        };
        accents = {
          orange = "#ff9800";
          yellow = "#ff6600";
          red = "#ff5722";
          green = "#4caf50";
          blue = "#2196f3";
          magenta = "#e040fb";
          purple = "#9c27b0";
          cyan = "#00bcd4";
        };
      };
    };
  };
}
