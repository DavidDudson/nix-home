#!/usr/bin/env bash
# Bluetooth device picker using fuzzel
# Left-click from waybar bluetooth module

SCAN_LABEL="󰂳  Scan for new devices"

# Build list of paired devices with connection status.
# Parse `Device AA:BB:...:FF Some Name` via read, no awk/cut spawns.
menu=""
while read -r _prefix mac name; do
    [ -z "$mac" ] && continue
    if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
        menu+="󰂱  $name [$mac]\n"
    else
        menu+="󰂯  $name [$mac]\n"
    fi
done < <(bluetoothctl devices Paired 2>/dev/null)

menu+="$SCAN_LABEL\n"

chosen=$(printf '%b' "$menu" | fuzzel --dmenu --prompt="󰂯 Bluetooth  ")
[ -z "$chosen" ] && exit 0

if [ "$chosen" = "$SCAN_LABEL" ]; then
    blueman-manager &
    exit 0
fi

# Extract MAC address from [XX:XX:XX:XX:XX:XX]
mac=$(echo "$chosen" | grep -oP '\[\K[A-F0-9:]+(?=\])')
[ -z "$mac" ] && exit 1

if echo "$chosen" | grep -q "^󰂱"; then
    # Connected — disconnect
    bluetoothctl disconnect "$mac" 2>/dev/null
    notify-send "Bluetooth" "Disconnected"
else
    # Paired but not connected — connect
    notify-send "Bluetooth" "Connecting..."
    if bluetoothctl connect "$mac" 2>/dev/null; then
        notify-send "Bluetooth" "Connected"
    else
        notify-send "Bluetooth" "Connection failed"
    fi
fi
