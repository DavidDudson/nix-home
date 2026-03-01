{
  config,
  pkgs,
  ...
}:

let
  extensionsRepo = pkgs.fetchFromGitHub {
    owner = "vicinaehq";
    repo = "extensions";
    rev = "cf30b80f619282d45b1748eb76e784a4f875bb01";
    hash = "sha256-KwNv+THKbNUey10q26NZPDMSzYTObRHaSDr81QP9CPY=";
  };
  mkExt =
    name:
    config.lib.vicinae.mkExtension {
      inherit name;
      src = extensionsRepo + "/extensions/${name}";
    };

  # Builder for extensions with optional native deps that fail under node-gyp
  # Sets npm_config_optional=false to skip optional native modules like usocket
  mkNativeExt =
    name:
    let
      src = extensionsRepo + "/extensions/${name}";
    in
    pkgs.buildNpmPackage {
      inherit name src;
      npmFlags = [ "--ignore-scripts" ];
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
        "bluetooth"
        "color-converter"
        "github"
        "hypr-keybinds"
        "nix"
        "player-pilot"
        "port-killer"
        "process-manager"
        "pulseaudio"
        "ssh"
        "wifi-commander"
      ]
      ++ [
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
