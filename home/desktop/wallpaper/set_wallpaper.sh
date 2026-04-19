#!/usr/bin/env bash
# Custom set_wallpaper hook for Variety.
# Sets the wallpaper via awww and regenerates Material You colors with matugen.
#
# Parameters (provided by Variety):
#   $1 - path to the wallpaper image (after effects)
#   $2 - "auto", "manual", or "refresh"
#   $3 - path to the original wallpaper image (before effects)
#   $4 - display mode

WP="$1"

if [ -z "$WP" ] || [ ! -f "$WP" ]; then
    echo "No wallpaper provided or file not found: $WP" >&2
    exit 1
fi

# Set wallpaper with awww (animated transitions)
awww img "$WP" \
    --transition-type grow \
    --transition-duration 2 \
    --transition-fps 60 \
    --transition-pos center

# Regenerate Material You colors from the wallpaper.
# --source-color-index 0 picks the dominant color non-interactively;
# matugen 4.0 would otherwise prompt via arrow-key UI and fail headlessly.
matugen --source-color-index 0 image "$WP"
