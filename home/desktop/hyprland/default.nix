{ pkgs, ... }:

let
  # Nixpkgs ships hyprspace built against Hyprland 0.54, but the pinned
  # Hyprland is 0.55+ and the LayoutManager header moved. Upstream KZDKM
  # hasn't merged a 0.55 fix yet — use 0xl30's fork (PR #230) until then.
  hyprspace = pkgs.hyprlandPlugins.hyprspace.overrideAttrs (_old: {
    version = "unstable-2026-05-13-0xl30";
    src = pkgs.fetchFromGitHub {
      owner = "0xl30";
      repo = "Hyprspace";
      rev = "5f12222eeab6cb3a0ff1237f7444eb0b8ca00351";
      hash = "sha256-Fd4LKjT904fxET4oWFvTLqozuhaUYg130zKW7ta1qIo=";
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
    plugins = [ hyprspace ];
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
