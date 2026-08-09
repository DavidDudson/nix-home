#!/usr/bin/env bash
# Waybar disk module: root % in the text, per-mount usage table in the tooltip.
# Mirrors memory.sh / cpu.sh — same JSON shape, same warning/critical thresholds.
# Tooltip lists every real filesystem (ext*/btrfs/xfs/zfs/vfat/f2fs) plus tmpfs
# mounts that actually hold data, so the user sees both physical drives and the
# noisy tmpfs/shm scratch areas that consume RAM.

# NOTE: pipefail intentionally omitted — see memory.sh for the SIGPIPE/head
# rationale (head -N closes the pipe early; pipefail would flag that as failure).
set -eu

# Root % drives the bar text + warning class.
read -r root_pct < <(
    df -P / | awk 'NR==2 { sub(/%/, "", $5); print $5 }'
)

# Per-mount rows. Real filesystems unconditionally; tmpfs/devtmpfs only when
# they're holding data so the tooltip stays signal-heavy. df -PT prints 1K
# blocks; we human-format used/size in the same awk pass.
table=$(
    df --output=source,fstype,size,used,avail,pcent,target 2>/dev/null \
        | awk '
            function h(k) {
                if (k+0 >= 1048576) return sprintf("%.1fG", k/1048576);
                if (k+0 >= 1024)    return sprintf("%.0fM", k/1024);
                return sprintf("%dK", k);
            }
            NR == 1 { next }
            {
                src=$1; fs=$2; size=$3; used=$4; avail=$5; pct=$6; mnt=$7;
                real = (fs ~ /^(ext[234]|btrfs|xfs|zfs|vfat|f2fs|ntfs|exfat)$/);
                scratch = (fs ~ /^(tmpfs|devtmpfs)$/) && (used+0 > 0);
                if (!real && !scratch) next;
                # Skip noise: per-user runtime dirs and credentials mounts.
                if (mnt ~ /^\/run\/(user|credentials)/) next;
                # Shorten device source: strip /dev/mapper or /dev/, unescape
                # LVM double-dashes (LVM renders a literal "-" in vg/lv names as
                # "--" in /dev/mapper paths — collapse back so vg0-nixos--home
                # reads as vg0-nixos-home).
                sub(/^\/dev\/mapper\//, "", src);
                sub(/^\/dev\//, "", src);
                gsub(/--/, "-", src);
                printf "%-20s %-18s %7s / %-7s  %4s  %s\n", src, mnt, h(used), h(size), pct, fs;
            }' \
        | sort -k2,2
)

tooltip=$(printf 'Disk: %d%% (/)\n\n%-20s %-18s %17s  %4s  %s\n%s' \
    "$root_pct" "Device" "Mount" "Used / Total" "Use%" "FS" "$table")

# Match the old built-in disk module thresholds: warning ≥80, critical ≥90.
class="normal"
if   [ "$root_pct" -ge 90 ]; then class="critical"
elif [ "$root_pct" -ge 80 ]; then class="warning"
fi

jq -cn \
    --arg text "${root_pct}%" \
    --arg tooltip "$tooltip" \
    --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class, percentage: ($text | rtrimstr("%") | tonumber)}'
