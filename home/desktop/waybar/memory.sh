#!/usr/bin/env bash
# Waybar memory module: % used in the text, top 10 apps by RSS in the tooltip.
# Apps are grouped by `comm` so all Firefox/Electron subprocesses collapse
# into a single line, matching how the user actually thinks about memory.

set -euo pipefail

read -r mem_total mem_avail < <(
    awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {print t, a}' /proc/meminfo
)
mem_used=$((mem_total - mem_avail))
pct=$((mem_used * 100 / mem_total))

# KiB → "X.YG" / "X.YM" — matches waybar's built-in formatting.
human() {
    awk -v kib="$1" 'BEGIN {
        if (kib >= 1048576) printf "%.1fG", kib / 1048576;
        else if (kib >= 1024) printf "%.0fM", kib / 1024;
        else printf "%dK", kib;
    }'
}

used_h=$(human "$mem_used")
total_h=$(human "$mem_total")

# Top 10 applications by summed RSS. comm:30 widens the column so chromium /
# .firefox-wrapped / electron names aren't truncated before grouping.
top=$(
    ps -eo comm:30,rss --no-headers \
        | awk '{
            name=$1;
            sub(/^\.?/, "", name);              # strip leading dot from nix wrappers
            sub(/-wrapped(_)?$/, "", name);     # collapse foo-wrapped → foo
            r[name] += $2;
        } END {
            for (n in r) printf "%d %s\n", r[n], n;
        }' \
        | sort -k1 -n -r \
        | head -10 \
        | awk '{
            kib = $1;
            $1 = "";
            sub(/^ /, "");
            if (kib >= 1048576) sz = sprintf("%6.1fG", kib / 1048576);
            else                sz = sprintf("%6.0fM", kib / 1024);
            printf "%s  %s\n", sz, $0;
        }'
)

tooltip=$(printf '%s / %s (%d%%)\n\n%s' "$used_h" "$total_h" "$pct" "$top")

# states= classes from waybar config: warning ≥ 80, critical ≥ 95.
class="normal"
if [ "$pct" -ge 95 ]; then class="critical"
elif [ "$pct" -ge 80 ]; then class="warning"
fi

jq -cn \
    --arg text "$pct%" \
    --arg tooltip "$tooltip" \
    --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class, percentage: ($text | rtrimstr("%") | tonumber)}'
