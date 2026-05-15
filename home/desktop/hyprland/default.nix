{ pkgs, ... }:

let
  # Nixpkgs ships hyprspace built against Hyprland 0.54, but the pinned
  # Hyprland is 0.55+ and the LayoutManager header moved. Upstream KZDKM
  # hasn't merged a 0.55 fix yet — use 0xl30's fork (PR #230) until then.
  # Hyprexpo was the previous choice; upstream dropped it on 2026-05-12.
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
    # hyprspace: workspace overview panel. Bound to Super+Tab in hyprland.conf.
    plugins = [ hyprspace ];
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  home.file = {
    ".config/hypr/appearance.conf".source = ./appearance.conf;
    ".config/hypr/input.conf".source = ./input.conf;
    ".config/hypr/keybindings.conf".source = ./keybindings.conf;
    ".config/hypr/rules.conf".source = ./rules.conf;
  };
}
