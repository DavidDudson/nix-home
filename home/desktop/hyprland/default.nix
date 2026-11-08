{ pkgs, ... }:

let
  # nixpkgs still ships hyprspace at the pre-V2-API 2026-05-28 rev, which does
  # not compile against Hyprland 0.56+ (AnimationManager.hpp moved). Upstream
  # HEAD carries the V2 plugin API migration plus the Hyprland 0.57 fix
  # (2026-10-30); the previous 2026-10-02 pin lacked the 0.57 fix. Drop once
  # nixpkgs picks up a rev at or past 8345bf6f.
  hyprspace = pkgs.hyprlandPlugins.hyprspace.overrideAttrs (_old: {
    version = "unstable-2026-10-30";
    src = pkgs.fetchFromGitHub {
      owner = "KZDKM";
      repo = "Hyprspace";
      rev = "8345bf6f623d486ca3f87f416ccf1412416eef08";
      hash = "sha256-4b3RPW+fEP0HLFFnY3JnRgeAspgpWa1Cjzlq3UKmQLk=";
    };
  });
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "lua";
    # hyprspace: workspace overview panel. Bound to Super+Tab via the
    # hyprland.start hook in hyprland.lua (after plugin load).
    plugins = [
      hyprspace
    ];
    extraConfig = builtins.readFile ./hyprland.lua;
  };

  # Split sub-configs deployed alongside hyprland.lua so require() can find
  # them via Hyprland's Lua module path.
  home.file = {
    ".config/hypr/appearance.lua".source = ./appearance.lua;
    ".config/hypr/input.lua".source = ./input.lua;
    ".config/hypr/keybindings.lua".source = ./keybindings.lua;
    ".config/hypr/rules.lua".source = ./rules.lua;
  };
}
