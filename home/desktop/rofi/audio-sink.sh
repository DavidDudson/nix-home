#!/usr/bin/env bash

# Get list of sinks with their descriptions
get_sinks() {
    pactl list sinks | awk '
        /^Sink #/ { sink_id = $2; gsub(/#/, "", sink_id) }
        /Description:/ {
            desc = $0;
            gsub(/^\s*Description:\s*/, "", desc);
            print sink_id ": " desc
        }
    '
}

# Get current default sink
get_default() {
    pactl get-default-sink
}

# Mark current sink in the list
sinks=$(get_sinks)
default_sink=$(get_default)

# Add indicator to current sink
marked_sinks=$(echo "$sinks" | while read -r line; do
    sink_id=$(echo "$line" | cut -d: -f1)
    sink_name=$(pactl list sinks | awk -v id="$sink_id" '
        /^Sink #'"$sink_id"'$/ { found=1 }
        found && /Name:/ { print $2; exit }
    ')
    if [[ "$sink_name" == "$default_sink" ]]; then
        echo "󰓃 $line"
    else
        echo "󰓄 $line"
    fi
done)

# Show rofi menu
chosen=$(echo "$marked_sinks" | rofi -dmenu -i -p "󰕾 Audio Output")

if [[ -n "$chosen" ]]; then
    # Extract sink ID from selection
    sink_id=$(echo "$chosen" | sed 's/^[^ ]* //' | cut -d: -f1)
    pactl set-default-sink "$sink_id"
fi
