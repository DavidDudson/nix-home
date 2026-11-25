{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "lua";
    # hyprspace: workspace overview panel. Bound to Super+Tab via the
    # hyprland.start hook in hyprland.lua (after plugin load).
    plugins = [
      pkgs.hyprlandPlugins.hyprspace
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
