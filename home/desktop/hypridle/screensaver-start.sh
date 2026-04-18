#!/usr/bin/env bash
# Start mpvpaper screensaver loop using videos from ~/Videos/screensaver.
# Does not lock the session — any input wakes and triggers the stop script.
set -euo pipefail

VIDEO_DIR="$HOME/Videos/screensaver"
mkdir -p "$VIDEO_DIR"

shopt -s nullglob
videos=("$VIDEO_DIR"/*.mp4 "$VIDEO_DIR"/*.webm "$VIDEO_DIR"/*.mkv "$VIDEO_DIR"/*.mov)
shopt -u nullglob

if [ ${#videos[@]} -eq 0 ]; then
    notify-send "Screensaver" "Drop a video in $VIDEO_DIR"
    exit 0
fi

pkill -x mpvpaper || true
mpvpaper -f -o "no-audio loop-playlist=inf mute=yes shuffle" ALL "$VIDEO_DIR"
