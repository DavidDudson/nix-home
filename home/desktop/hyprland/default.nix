{ pkgs, ... }:

let
  # ImanolBarba's V2 plugin API migration (PR #238) landed upstream on
  # 2026-10-02, so the fork pin is retired for upstream HEAD. The override
  # itself stays: nixpkgs still ships hyprspace at the pre-merge 2026-05-28
  # rev, which does not compile against Hyprland 0.56 (AnimationManager.hpp
  # moved). Drop it once nixpkgs picks up the merge.
  hyprspace = pkgs.hyprlandPlugins.hyprspace.overrideAttrs (_old: {
    version = "unstable-2026-10-02";
    src = pkgs.fetchFromGitHub {
      owner = "KZDKM";
      repo = "Hyprspace";
      rev = "cf08bed82621c1fb943ef4934ff0ba36540fea77";
      hash = "sha256-P27tvgpduDsMjk9mSti4We+a3kzYWYWznZKizvnyS+Q=";
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
