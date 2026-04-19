{ pkgs, ... }:

let
  # Nixpkgs ships hyprexpo 0.53.0 which doesn't compile against the pinned
  # hyprland 0.54.3 (HookSystemManager.hpp got refactored). Override the
  # source with an hyprland-plugins commit from after Vaxry's 2026-02-23
  # "chase hyprland" sync, so the plugin builds against 0.54+.
  hyprland-plugins-src = pkgs.fetchFromGitHub {
    owner = "hyprwm";
    repo = "hyprland-plugins";
    rev = "6059aca0cc623d8d896b02842606036c0954ba88"; # 2026-04-17
    hash = "sha256-NX0dSUS86OBXfhD77rsajp3nJKg43HYhVdvlo9FkCsg=";
  };

  hyprexpo = pkgs.hyprlandPlugins.hyprexpo.overrideAttrs (_old: {
    version = "unstable-2026-04-17";
    src = hyprland-plugins-src + "/hyprexpo";
  });
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    # hyprexpo: workspace-overview grid, bound to Super+Tab in keybindings.conf.
    plugins = [ hyprexpo ];
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  home.file = {
    ".config/hypr/appearance.conf".source = ./appearance.conf;
    ".config/hypr/input.conf".source = ./input.conf;
    ".config/hypr/keybindings.conf".source = ./keybindings.conf;
    ".config/hypr/rules.conf".source = ./rules.conf;
  };
}
