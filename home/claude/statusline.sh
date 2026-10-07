#!/usr/bin/env bash
# Claude Code statusline. Consumes stdin JSON from Claude Code.
# Sections: 5hr | weekly | context | git | project
# Pure-bash JSON extraction (no jq) for speed.

set -u

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

GREEN=$'\033[38;5;82m'
YELLOW=$'\033[38;5;226m'
RED=$'\033[38;5;203m'
CYAN=$'\033[38;5;39m'
MAGENTA=$'\033[38;5;213m'
BLUE=$'\033[38;5;75m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'
SEP="${DIM} │ ${RESET}"

printf -v NOW '%(%s)T' -1
INPUT=$(cat)

CWD=""; CTX_PCT=0; FH_PCT=0; WK_PCT=0; FH_RESET=0; WK_RESET=0
# context_window nests current_usage{} before used_percentage; allow one level.
_re='"context_window":\{([^{}]|\{[^{}]*\})*"used_percentage":([0-9]+)'; [[ $INPUT =~ $_re ]] && CTX_PCT="${BASH_REMATCH[2]}"
_re='"five_hour":\{[^}]*"used_percentage":([0-9]+)';     [[ $INPUT =~ $_re ]] && FH_PCT="${BASH_REMATCH[1]}"
_re='"five_hour":\{[^}]*"resets_at":([0-9]+)';           [[ $INPUT =~ $_re ]] && FH_RESET="${BASH_REMATCH[1]}"
_re='"seven_day":\{[^}]*"used_percentage":([0-9]+)';     [[ $INPUT =~ $_re ]] && WK_PCT="${BASH_REMATCH[1]}"
_re='"seven_day":\{[^}]*"resets_at":([0-9]+)';           [[ $INPUT =~ $_re ]] && WK_RESET="${BASH_REMATCH[1]}"
_re='"current_dir":"([^"]+)"';                           [[ $INPUT =~ $_re ]] && CWD="${BASH_REMATCH[1]}"
: "${CWD:=$PWD}"

# ── Rate limits: color by projected usage at reset ─────────────────
# projected = used% * window / elapsed. Green <75%, yellow <100%, red >=100%.
# Early in a window (<10% elapsed) projection is noisy; fall back to raw %.
fmt_left() {
    # $1 = seconds remaining -> "2h10m" or "3d4h"
    local s=$1
    if [ "$s" -ge 86400 ]; then printf '%dd%dh' $((s / 86400)) $(((s % 86400) / 3600))
    else printf '%dh%dm' $((s / 3600)) $(((s % 3600) / 60))
    fi
}
limit_label() {
    # $1 = icon, $2 = used%, $3 = resets_at epoch, $4 = window secs
    local used=$2 reset=$3 win=$4 left elapsed proj clr
    # rate_limits absent until first API response (or non-subscriber).
    [ "$reset" -eq 0 ] && [ "$used" -eq 0 ] && return
    if [ "$reset" -gt "$NOW" ]; then left=$((reset - NOW)); else left=0; fi
    [ "$left" -gt "$win" ] && left=$win
    elapsed=$((win - left))
    if [ "$reset" -gt 0 ] && [ $((elapsed * 10)) -ge "$win" ]; then
        proj=$((used * win / elapsed))
    else
        proj=$used
    fi
    if [ "$used" -ge 90 ] || [ "$proj" -ge 100 ]; then clr="$RED"
    elif [ "$proj" -ge 75 ]; then clr="$YELLOW"
    else clr="$GREEN"
    fi
    local out="${clr}$1 ${used}%"
    [ "$reset" -gt 0 ] && out+=" ${DIM}$(fmt_left "$left")"
    printf '%s' "${out}${RESET}"
}
FIVE_HR=$(limit_label "⏳" "$FH_PCT" "$FH_RESET" 18000)
WEEKLY=$(limit_label "📅" "$WK_PCT" "$WK_RESET" 604800)

# ── Context: warn from 20% used ────────────────────────────────────
if [ "$CTX_PCT" -ge 50 ]; then CTX="${RED}${BOLD}🪟 ${CTX_PCT}% ⚠${RESET}"
elif [ "$CTX_PCT" -ge 20 ]; then CTX="${YELLOW}🪟 ${CTX_PCT}% ⚠${RESET}"
else CTX="${CYAN}🪟 ${CTX_PCT}%${RESET}"
fi

# ── Git + project (dirty count cached 2s) ──────────────────────────
GIT_INFO=""
mapfile -t GITVALS < <(git -C "$CWD" rev-parse --abbrev-ref HEAD --show-toplevel 2>/dev/null)
BRANCH="${GITVALS[0]:-}"
TOPLEVEL="${GITVALS[1]:-}"
if [ -n "$BRANCH" ] && [ -n "$TOPLEVEL" ]; then
    CACHE="$CLAUDE_DIR/.git-dirty-${TOPLEVEL//\//_}"
    DIRTY=""
    if [ -f "$CACHE" ]; then
        mapfile -t C <"$CACHE"
        (( NOW - ${C[0]:-0} < 2 )) && DIRTY="${C[1]:-}"
    fi
    if [ -z "$DIRTY" ]; then
        mapfile -t D < <(git -C "$TOPLEVEL" status --porcelain --untracked-files=no 2>/dev/null)
        DIRTY=${#D[@]}
        printf '%s\n%s' "$NOW" "$DIRTY" >"$CACHE"
    fi
    if [ "$DIRTY" -gt 0 ]; then GIT_INFO="${MAGENTA}🌿 ${BRANCH}${RESET} ${RED}✏️${DIRTY}${RESET}"
    else GIT_INFO="${MAGENTA}🌿 ${BRANCH}${RESET}"
    fi
    PROJ="${BLUE}📂 ${TOPLEVEL##*/}${RESET}"
else
    PROJ="${BLUE}📂 ${CWD##*/}${RESET}"
fi

OUT=""
for PART in "$FIVE_HR" "$WEEKLY" "$CTX" "$GIT_INFO" "$PROJ"; do
    [ -z "$PART" ] && continue
    OUT="${OUT:+${OUT}${SEP}}${PART}"
done
printf '%s' "$OUT"
