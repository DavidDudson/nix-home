{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Wayland Core
    xdg-desktop-portal-termfilechooser
    xdg-desktop-portal-hyprland

    # Hyprland Tools
    hyprpicker # Color picker
    hyprlock # Screen locker
    hypridle # Idle daemon
    hyprpaper # Wallpaper
    hyprshade # Screen shader
    hyprpolkitagent # Authentication agent

    # Wayland Utilities
    waybar # Status bar
    pavucontrol # Audio control GUI
    cliphist # Clipboard manager
    wl-clipboard # Clipboard utilities

    # Theming
    nwg-look # GTK theme switcher

    # Screenshots & Recording
    grim # Screenshot tool (Wayland)
    slurp # Region selection for screenshots
    wf-recorder # Screen recorder (Wayland)

    # Graphics
    resvg # SVG renderer
  ];
}
