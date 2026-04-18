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
    awww # Animated wallpaper daemon with transitions (formerly swww)
    variety # Wallpaper downloader and changer (Unsplash, Wallhaven, etc.)
    hyprshade # Screen shader
    hyprpolkitagent # Authentication agent
    mpvpaper # Video/animated wallpaper via mpv (used for screensaver)

    # Wayland Utilities
    waybar # Status bar
    fuzzel # Wayland-native dmenu/launcher for picker menus
    libnotify # Desktop notifications (notify-send)
    pavucontrol # Audio control GUI
    cliphist # Clipboard manager
    wl-clipboard # Clipboard utilities

    # Theming
    matugen # Material You color generation from wallpapers
    nwg-look # GTK theme switcher

    # Screenshots & Recording
    grim # Screenshot tool (Wayland)
    slurp # Region selection for screenshots
    wf-recorder # Screen recorder (Wayland)

    # Graphics
    resvg # SVG renderer
  ];
}
