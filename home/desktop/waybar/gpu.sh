#!/usr/bin/env bash
# Waybar GPU module: util% + temp in the text, top processes by SM% in the
# tooltip. Mirrors cpu.sh / memory.sh; uses nvidia-smi pmon for per-process
# utilization and --query-compute-apps for accurate per-process VRAM (pmon's
# `mem` column is a percentage of framebuffer, not megabytes).

# NOTE: pipefail intentionally omitted — see memory.sh for the SIGPIPE/head
# rationale.
set -eu

# Overall GPU stats: util%, VRAM used/total, temp.
read -r util mem_used mem_total temp < <(
    nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
        --format=csv,noheader,nounits \
        | awk -F', ' '{print $1, $2, $3, $4}'
)

# Per-process VRAM map (MiB). Built from --query-compute-apps so the tooltip
# shows real megabytes rather than the framebuffer-% that pmon reports.
vram_map=$(
    nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits 2>/dev/null \
        | awk -F', ' 'NF>=2 {printf "%s %s\n", $1, $2}'
)

# Per-pid SM% from pmon (only source of per-process utilization). pmon truncates
# command names at ~16 chars and shows X-server (Xwayland/Hyprland) compositor
# rows that aren't what the user cares about, so we resolve the real comm via
# /proc/<pid>/comm and group there. Strip leading `.` + `-wrapped` suffix the
# same way memory.sh does so nix wrappers collapse with their real binary.
top=$(
    nvidia-smi pmon -c 1 2>/dev/null \
        | awk '/^#/ { next } { sm = ($4 == "-") ? 0 : $4; print $2, sm }' \
        | while read -r pid sm; do
            # Resolve the real executable. /proc/<pid>/comm is capped at
            # TASK_COMM_LEN (16 chars); /proc/<pid>/cmdline can be rewritten
            # by sandboxed apps (Chromium GPU subprocesses set argv[0] to the
            # render-node path). /proc/<pid>/exe is the kernel-tracked binary
            # and survives both, so prefer it; fall back to comm only when the
            # exe symlink isn't readable (kernel threads / dead procs).
            exe=$(readlink "/proc/${pid}/exe" 2>/dev/null || true)
            if [ -n "$exe" ]; then
                comm=$(basename -- "$exe")
            else
                comm=$(cat "/proc/${pid}/comm" 2>/dev/null || echo "[pid ${pid}]")
            fi
            printf '%s %s %s\n' "$pid" "$sm" "$comm"
        done \
        | awk -v vram="$vram_map" '
            BEGIN {
                # Build pid → MiB lookup from the compute-apps query.
                n = split(vram, lines, "\n");
                for (i = 1; i <= n; i++) {
                    split(lines[i], f, " ");
                    if (f[1] != "") mem_pid[f[1]] = f[2];
                }
            }
            {
                pid=$1; sm=$2; name=$3;
                sub(/^\.?/, "", name);              # strip leading dot from nix wrappers
                sub(/-wrapped(_)?$/, "", name);     # collapse foo-wrapped → foo
                sm_sum[name] += sm;
                mem_sum[name] += (mem_pid[pid] + 0);
            }
            END {
                for (c in sm_sum) printf "%.0f %d %s\n", sm_sum[c], mem_sum[c], c;
            }' \
        | sort -k1,1nr -k2,2nr \
        | head -10 \
        | awk '{
            sm = $1; mib = $2; $1 = ""; $2 = "";
            sub(/^  /, "");
            if (mib >= 1024) sz = sprintf("%6.1fG", mib / 1024);
            else             sz = sprintf("%6dM", mib);
            printf "%3d%%  %s  %s\n", sm, sz, $0;
        }'
)

tooltip=$(printf 'GPU: %s%%  VRAM: %s / %s MiB  %s°C\n\n%4s  %7s  %s\n%s' \
    "$util" "$mem_used" "$mem_total" "$temp" "SM%" "VRAM" "Process" "$top")

# Match cpu/memory thresholds: warning ≥80, critical ≥95.
class="normal"
if   [ "$util" -ge 95 ]; then class="critical"
elif [ "$util" -ge 80 ]; then class="warning"
fi

jq -cn \
    --arg text "󰢮 ${util}% 󰔏 ${temp}°C" \
    --arg tooltip "$tooltip" \
    --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
