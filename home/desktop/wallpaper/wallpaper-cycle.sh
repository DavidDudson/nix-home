#!/usr/bin/env bash
# Cycle wallpapers using awww, regenerate theme colors with matugen.

WALLPAPER_DIR="$HOME/.local/share/wallpapers"
INTERVAL=1800 # 30 minutes

# Ensure fallback colors exist before first matugen run
[ -f "$HOME/.config/hypr/colors.conf" ] || cp "$HOME/.config/matugen/fallback/colors.conf" "$HOME/.config/hypr/colors.conf"
[ -f "$HOME/.config/waybar/colors.css" ] || cp "$HOME/.config/matugen/fallback/colors.css" "$HOME/.config/waybar/colors.css"

set_wallpaper() {
    local img="$1"
    awww img "$img" \
        --transition-type grow \
        --transition-duration 2 \
        --transition-fps 60 \
        --transition-pos center

    # Generate Material You colors from the wallpaper
    matugen image "$img"
}

# Find wallpaper images (exclude fallback files)
mapfile -t wallpapers < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.gif' -o -name '*.webp' \) | sort)

if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Wait for awww-daemon to be ready
sleep 1

idx=0
while true; do
    set_wallpaper "${wallpapers[$idx]}"
    idx=$(( (idx + 1) % ${#wallpapers[@]} ))
    sleep "$INTERVAL"
done
