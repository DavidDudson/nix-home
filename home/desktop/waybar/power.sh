#!/usr/bin/env bash
# Waybar power menu. Renders a session-action chooser via vicinae's dmenu
# (consistent UI with the launcher), then dispatches to the chosen action.
# Replaces the previous `vicinae vicinae://extensions/vicinae/power` deeplink
# which pointed at a non-existent extension (vicinaehq/extensions only ships
# `power-profile`, which manages CPU governors — not a shutdown menu).

set -eu

choice=$(
    printf '%s\n' \
        " Lock" \
        "󰍃 Logout" \
        "󰒲 Suspend" \
        "󰜉 Reboot" \
        "󰐥 Shutdown" \
    | vicinae dmenu \
        --navigation-title "Power" \
        --section-title "Session" \
        --placeholder "Select an action…" \
        --no-footer
)

case "$choice" in
    *Lock)     exec hyprlock ;;
    *Logout)   exec hyprctl dispatch exit ;;
    *Suspend)  exec systemctl suspend ;;
    *Reboot)   exec systemctl reboot ;;
    *Shutdown) exec systemctl poweroff ;;
    "")        exit 0 ;;
    *)         echo "[power] unknown choice: $choice" >&2; exit 1 ;;
esac
