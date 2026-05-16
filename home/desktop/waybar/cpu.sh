#!/usr/bin/env bash
# Waybar CPU module: total % in the text, top 10 apps by CPU in the tooltip.
# Apps grouped by `comm` so subprocess swarms (Chromium/Firefox/Electron)
# collapse into single rows, mirroring memory.sh.

# NOTE: pipefail intentionally omitted — see memory.sh for the SIGPIPE/head
# rationale.
set -eu

# Total CPU% via two /proc/stat snapshots ~300 ms apart. This is the real
# instantaneous load; the per-process table below uses ps's lifetime %CPU
# (matches htop's default view) so process names aren't truncated.
read_cpu_total() {
    awk '/^cpu / {
        idle  = $5 + $6
        total = $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9
        print idle, total
    }' /proc/stat
}

read -r idle1 total1 < <(read_cpu_total)
sleep 0.3
read -r idle2 total2 < <(read_cpu_total)

dt=$((total2 - total1))
di=$((idle2 - idle1))
if [ "$dt" -gt 0 ]; then
    pct=$(( (dt - di) * 100 / dt ))
else
    pct=0
fi

# Top 10 applications by summed %CPU. comm:30 widens the column so chromium /
# .firefox-wrapped / electron names aren't truncated before grouping.
top=$(
    ps -eo comm:30,pcpu --no-headers \
        | awk '{
            name=$1;
            sub(/^\.?/, "", name);              # strip leading dot from nix wrappers
            sub(/-wrapped(_)?$/, "", name);     # collapse foo-wrapped → foo
            r[name] += $2;
        } END {
            for (n in r) printf "%.1f %s\n", r[n], n;
        }' \
        | sort -k1 -n -r \
        | head -10 \
        | awk '{
            cpu = $1;
            $1 = "";
            sub(/^ /, "");
            printf "%5.1f%%  %s\n", cpu, $0;
        }'
)

tooltip=$(printf 'CPU: %d%%\n\n%s' "$pct" "$top")

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
