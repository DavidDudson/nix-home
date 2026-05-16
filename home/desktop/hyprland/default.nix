{ pkgs, ... }:

let
  # Nixpkgs ships hyprspace built against Hyprland 0.54, but the pinned
  # Hyprland is 0.55+ and the LayoutManager header moved. Two upstream PRs
  # are needed: #230 (0.55 API) and #231 (guard reloadConfig() against
  # null values during the Lua config manager's startup reload, which
  # otherwise segfaults and drops us into safe mode). colonelpanic8's
  # branch stacks #231 on top of #230.
  hyprspace = pkgs.hyprlandPlugins.hyprspace.overrideAttrs (_old: {
    version = "unstable-2026-05-15-colonelpanic8";
    src = pkgs.fetchFromGitHub {
      owner = "colonelpanic8";
      repo = "Hyprspace";
      rev = "bf2ef21007e8963fcb0016ae26b6b21704946f80";
      hash = "sha256-q+5ETwj+oiZBT9j6/huwB8nwV4nbZdZmCrchL2E7tDQ=";
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
    # hyprbars: thin top accent strip used as a focus indicator
    # (Vicinae-style, matching the waybar selected-workspace hint).
    plugins = [
      hyprspace
      pkgs.hyprlandPlugins.hyprbars
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
