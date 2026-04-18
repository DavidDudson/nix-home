#!/usr/bin/env bash
# WiFi network picker using fuzzel
# Left-click from waybar network module

# Trigger async rescan
nmcli device wifi rescan 2>/dev/null &

# Get active WiFi connection name
active=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | \
    grep ':802-11-wireless' | cut -d: -f1 | head -1)

# Build SSID list (unique, sorted by signal strength descending)
ssids=$(nmcli -t -f SSID,SIGNAL device wifi list 2>/dev/null | \
    awk -F: '$1 != "" && !seen[$1]++' | \
    sort -t: -k2 -rn | cut -d: -f1)

if [ -z "$ssids" ]; then
    notify-send "WiFi" "No networks found"
    exit 1
fi

# Format menu — mark currently connected network
menu=""
while IFS= read -r ssid; do
    if [ "$ssid" = "$active" ]; then
        menu+="  $ssid\n"
    else
        menu+="$ssid\n"
    fi
done <<< "$ssids"

chosen=$(printf '%b' "$menu" | fuzzel --dmenu --prompt="󰤨 WiFi  ")
[ -z "$chosen" ] && exit 0

# Strip connected marker if present
ssid="${chosen#  }"

# Connect
if nmcli -t -f NAME connection show 2>/dev/null | grep -qFx "$ssid"; then
    # Known network — connect directly
    if nmcli connection up "$ssid" 2>/dev/null; then
        notify-send "WiFi" "Connected to $ssid"
    else
        notify-send "WiFi" "Failed to connect to $ssid"
    fi
else
    # Unknown network — open terminal UI for password entry
    rio -e nmtui connect "$ssid"
fi
