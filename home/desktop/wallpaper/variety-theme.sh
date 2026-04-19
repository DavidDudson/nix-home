#!/usr/bin/env bash
# Switch between named Variety wallpaper theme profiles.
#
# Each theme is a Variety profile at ~/.config/variety-profiles/<theme>/
# with its own [sources] list. The current theme is persisted in
# $XDG_STATE_HOME/variety-theme so the login exec-once picks it up
# again on the next session.
#
# Usage:
#   variety-theme start           # launch variety with persisted theme
#   variety-theme next            # rotate to next theme and notify
#   variety-theme set <name>      # switch to specific theme
#   variety-theme current         # print current theme name

set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/variety-theme"
THEMES=(landscapes space anime cyberpunk minimal)

current() {
    cat "$STATE" 2>/dev/null || echo "${THEMES[0]}"
}

start() {
    local theme="$1"
    mkdir -p "$(dirname "$STATE")"
    echo "$theme" >"$STATE"
    nohup variety --profile="$theme" >/dev/null 2>&1 &
    # Waybar's wallpaper module listens on SIGRTMIN+10 to refresh tooltip.
    pkill -SIGRTMIN+10 waybar 2>/dev/null || true
}

restart() {
    variety --quit 2>/dev/null || true
    sleep 0.3
    start "$1"
}

case "${1:-start}" in
start)
    start "$(current)"
    ;;
current)
    current
    ;;
set)
    if [ -z "${2:-}" ]; then
        echo "theme name required" >&2
        exit 1
    fi
    restart "$2"
    notify-send -a variety "Wallpaper" "Theme: $2"
    ;;
next)
    cur=$(current)
    idx=0
    for i in "${!THEMES[@]}"; do
        if [ "${THEMES[$i]}" = "$cur" ]; then
            idx=$i
            break
        fi
    done
    next_idx=$(((idx + 1) % ${#THEMES[@]}))
    next="${THEMES[$next_idx]}"
    restart "$next"
    notify-send -a variety "Wallpaper" "Theme: $next"
    ;;
*)
    echo "Usage: $0 {start|next|set <name>|current}" >&2
    exit 1
    ;;
esac
