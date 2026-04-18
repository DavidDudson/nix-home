#!/usr/bin/env bash
# Claude Code statusline. Consumes stdin JSON from Claude Code for model,
# rate limits, context %, cost. Pure-bash JSON extraction (no jq) for speed.
# Sections: caveman | 5hr | weekly | context | effort | model | diff | dur | cost | git | project | version

set -u

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# --- Colors ---
ORANGE=$'\033[38;5;172m'
CYAN=$'\033[38;5;39m'
GREEN=$'\033[38;5;82m'
YELLOW=$'\033[38;5;226m'
MAGENTA=$'\033[38;5;213m'
BLUE=$'\033[38;5;75m'
RED=$'\033[38;5;203m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'
SEP="${DIM} │ ${RESET}"

# ── Single date read ───────────────────────────────────────────────
read -r HH MM SS DOW EPOCH < <(date -u +"%H %M %S %u %s")
SECS_TODAY=$((10#$HH * 3600 + 10#$MM * 60 + 10#$SS))

# ── Slurp stdin ────────────────────────────────────────────────────
INPUT=$(cat)

# ── Pure-bash JSON field extraction via regex ──────────────────────
# Assumes Claude Code emits compact JSON with predictable field order.
# Inlined `[[ =~ ]]` + BASH_REMATCH avoids subshell spawns from $(fn).
MODEL_ID=""; MODEL_DISPLAY=""; CWD=""
CTX_PCT=0; FH_PCT=0; WK_PCT=0; COST=0
LINES_ADD=0; LINES_REM=0; DURATION_MS=0
OVER_200K=false

_re='"id":"([^"]+)"';                                [[ $INPUT =~ $_re ]] && MODEL_ID="${BASH_REMATCH[1]}"
_re='"display_name":"([^"]+)"';                      [[ $INPUT =~ $_re ]] && MODEL_DISPLAY="${BASH_REMATCH[1]}"
_re='"context_window":\{[^}]*"used_percentage":([0-9]+)'; [[ $INPUT =~ $_re ]] && CTX_PCT="${BASH_REMATCH[1]}"
_re='"five_hour":\{[^}]*"used_percentage":([0-9]+)'; [[ $INPUT =~ $_re ]] && FH_PCT="${BASH_REMATCH[1]}"
_re='"seven_day":\{[^}]*"used_percentage":([0-9]+)'; [[ $INPUT =~ $_re ]] && WK_PCT="${BASH_REMATCH[1]}"
_re='"total_cost_usd":([0-9]+(\.[0-9]+)?)';          [[ $INPUT =~ $_re ]] && COST="${BASH_REMATCH[1]}"
_re='"total_lines_added":([0-9]+)';                  [[ $INPUT =~ $_re ]] && LINES_ADD="${BASH_REMATCH[1]}"
_re='"total_lines_removed":([0-9]+)';                [[ $INPUT =~ $_re ]] && LINES_REM="${BASH_REMATCH[1]}"
_re='"total_duration_ms":([0-9]+)';                  [[ $INPUT =~ $_re ]] && DURATION_MS="${BASH_REMATCH[1]}"
_re='"current_dir":"([^"]+)"';                       [[ $INPUT =~ $_re ]] && CWD="${BASH_REMATCH[1]}"
[[ $INPUT =~ \"exceeds_200k_tokens\":true ]] && OVER_200K=true
: "${CWD:=$PWD}"

# ── Caveman flag ───────────────────────────────────────────────────
CAVEMAN=""
FLAG="$CLAUDE_DIR/.caveman-active"
if [ -f "$FLAG" ] && [ ! -L "$FLAG" ]; then
    MODE=$(<"$FLAG")
    MODE="${MODE,,}"
    MODE="${MODE//[^a-z0-9-]/}"
    case "$MODE" in
        off)               CAVEMAN="${DIM}🦴 off${RESET}" ;;
        lite)              CAVEMAN="${ORANGE}🦴 LITE${RESET}" ;;
        full|"")           CAVEMAN="${ORANGE}${BOLD}🦴 CAVEMAN${RESET}" ;;
        ultra)             CAVEMAN="${RED}${BOLD}🦴 ULTRA${RESET}" ;;
        wenyan*)           CAVEMAN="${ORANGE}🦴 文言${RESET}" ;;
        commit|review|compress)
            CAVEMAN="${ORANGE}🦴 ${MODE^^}${RESET}" ;;
    esac
fi

# ── Usage: 5hr block + weekly reset windows ────────────────────────
BLOCK_SECS=18000
REMAINING=$((BLOCK_SECS - SECS_TODAY % BLOCK_SECS))
REM_H=$((REMAINING / 3600))
REM_M=$(((REMAINING % 3600) / 60))

pct_color() {
    if [ "$1" -ge 80 ]; then printf '%s' "$RED"
    elif [ "$1" -ge 50 ]; then printf '%s' "$YELLOW"
    else printf '%s' "$CYAN"
    fi
}
FIVE_HR="$(pct_color "$FH_PCT")⏳ ${FH_PCT}%  ${REM_H}h${REM_M}m${RESET}"

DAYS_TO_MON=$(((8 - DOW) % 7))
[ "$DAYS_TO_MON" -eq 0 ] && [ "$SECS_TODAY" -gt 0 ] && DAYS_TO_MON=7
SECS_TO_MON=$((DAYS_TO_MON * 86400 - SECS_TODAY))
[ "$SECS_TO_MON" -lt 0 ] && SECS_TO_MON=$((SECS_TO_MON + 604800))
W_D=$((SECS_TO_MON / 86400))
W_H=$(((SECS_TO_MON % 86400) / 3600))

if [ "$WK_PCT" -ge 80 ]; then WK_CLR="$RED"
elif [ "$WK_PCT" -ge 50 ]; then WK_CLR="$YELLOW"
else WK_CLR="$GREEN"
fi
WEEKLY="${WK_CLR}📅 ${WK_PCT}%  ${W_D}d${W_H}h${RESET}"

# ── Context window ─────────────────────────────────────────────────
CTX_LABEL=""
if [ "$CTX_PCT" -gt 0 ] || [ "$OVER_200K" = "true" ]; then
    if [ "$CTX_PCT" -ge 80 ] || [ "$OVER_200K" = "true" ]; then CTX_CLR="$RED"
    elif [ "$CTX_PCT" -ge 50 ]; then CTX_CLR="$YELLOW"
    else CTX_CLR="$CYAN"
    fi
    WARN=""
    [ "$OVER_200K" = "true" ] && WARN=" ⚠"
    CTX_LABEL="${CTX_CLR}🪟 ${CTX_PCT}%${WARN}${RESET}"
fi

# ── Effort flag ────────────────────────────────────────────────────
EFFORT_LABEL="${DIM}🧠 —${RESET}"
EFFORT_FILE="$CLAUDE_DIR/.effort-level"
if [ -f "$EFFORT_FILE" ] && [ ! -L "$EFFORT_FILE" ]; then
    EFF=$(<"$EFFORT_FILE")
    EFF="${EFF,,}"
    EFF="${EFF//[^a-z0-9]/}"
    case "$EFF" in
        low|min)    EFFORT_LABEL="${DIM}🧠 low${RESET}" ;;
        medium|med) EFFORT_LABEL="${YELLOW}🧠 med${RESET}" ;;
        high|max)   EFFORT_LABEL="${GREEN}${BOLD}🧠 max${RESET}" ;;
        "")         ;;
        *)          EFFORT_LABEL="${YELLOW}🧠 ${EFF}${RESET}" ;;
    esac
fi

# ── Model label (from JSON) ────────────────────────────────────────
case "$MODEL_ID" in
    *opus*4-7*)   MN="opus-4.7"; MCLR="${RED}${BOLD}" ;;
    *opus*4-6*)   MN="opus-4.6"; MCLR="${RED}${BOLD}" ;;
    *opus*4-5*)   MN="opus-4.5"; MCLR="${RED}${BOLD}" ;;
    *opus*)       MN="opus";     MCLR="${RED}${BOLD}" ;;
    *sonnet*4-6*) MN="sonnet-4.6"; MCLR="$CYAN" ;;
    *sonnet*4-5*) MN="sonnet-4.5"; MCLR="$CYAN" ;;
    *sonnet*)     MN="sonnet";   MCLR="$CYAN" ;;
    *haiku*)      MN="haiku";    MCLR="$GREEN" ;;
    "")           MN="${MODEL_DISPLAY:-unknown}"; MCLR="$DIM" ;;
    *)            MN="$MODEL_ID"; MCLR="$DIM" ;;
esac
MODEL_LABEL="${MCLR}🤖 ${MN}${RESET}"

# ── Cache helpers: line1=timestamp, line2=value ────────────────────
# Avoids `stat` spawns by keeping mtime inside the file.
read_cache() {
    # $1 = file, $2 = max_age; sets CACHE_VAL or empty if stale/missing.
    CACHE_VAL=""
    [ -f "$1" ] || return 1
    mapfile -t _LINES <"$1"
    local ts="${_LINES[0]:-0}"
    (( EPOCH - ts < $2 )) || return 1
    CACHE_VAL="${_LINES[1]:-}"
}
write_cache() {
    # $1 = file, $2 = value
    printf '%s\n%s' "$EPOCH" "$2" >"$1"
}

# ── Git: single rev-parse, cached dirty count, no-untracked ───────
GIT_INFO=""
PROJ=""
mapfile -t GITVALS < <(git -C "$CWD" rev-parse --abbrev-ref HEAD --show-toplevel 2>/dev/null)
BRANCH="${GITVALS[0]:-}"
TOPLEVEL="${GITVALS[1]:-}"
if [ -n "$BRANCH" ] && [ -n "$TOPLEVEL" ]; then
    DIRTY_CACHE="$CLAUDE_DIR/.git-dirty-${TOPLEVEL//\//_}"
    read_cache "$DIRTY_CACHE" 2
    DIRTY="${CACHE_VAL:-}"
    if [ -z "$DIRTY" ]; then
        mapfile -t DIRTY_LINES < <(git -C "$TOPLEVEL" status --porcelain --untracked-files=no 2>/dev/null)
        DIRTY=${#DIRTY_LINES[@]}
        write_cache "$DIRTY_CACHE" "$DIRTY"
    fi
    if [ "$DIRTY" -gt 0 ]; then
        GIT_INFO="${MAGENTA}🌿 ${BRANCH}${RESET} ${RED}✏️${DIRTY}${RESET}"
    else
        GIT_INFO="${MAGENTA}🌿 ${BRANCH}${RESET} ${GREEN}✅${RESET}"
    fi
    PROJ="${BLUE}📂 ${TOPLEVEL##*/}${RESET}"
else
    PROJ="${BLUE}📂 ${CWD##*/}${RESET}"
fi

# ── Version (both cached 6h) ───────────────────────────────────────
VMAX=21600
VERSION_LABEL=""

read_cache "$CLAUDE_DIR/.version-current-cache" "$VMAX"
CURRENT_VER="$CACHE_VAL"
if [ -z "$CURRENT_VER" ]; then
    CURRENT_VER=$(timeout 3 claude --version 2>/dev/null | head -1 | grep -oE '[0-9.]+' | head -1)
    [ -n "$CURRENT_VER" ] && write_cache "$CLAUDE_DIR/.version-current-cache" "$CURRENT_VER"
fi

read_cache "$CLAUDE_DIR/.version-check-cache" "$VMAX"
LATEST_VER="$CACHE_VAL"
if [ -z "$LATEST_VER" ]; then
    LATEST_VER=$(timeout 3 npm view @anthropic-ai/claude-code version 2>/dev/null | tr -d '\n\r')
    [ -n "$LATEST_VER" ] && write_cache "$CLAUDE_DIR/.version-check-cache" "$LATEST_VER"
fi

if [ -n "$CURRENT_VER" ]; then
    if [ -n "$LATEST_VER" ] && [ "$CURRENT_VER" != "$LATEST_VER" ]; then
        VERSION_LABEL="${YELLOW}📦 v${CURRENT_VER}${RESET} ${RED}⬆️ ${LATEST_VER}${RESET}"
    else
        VERSION_LABEL="${DIM}📦 v${CURRENT_VER} ✅${RESET}"
    fi
fi

# ── Cost + activity ────────────────────────────────────────────────
COST_FMT=$(printf '%.2f' "$COST" 2>/dev/null || printf '%s' "$COST")
MINS=$((DURATION_MS / 60000))
if [ "$MINS" -lt 60 ]; then DUR="${MINS}m"
else DUR="$((MINS / 60))h$((MINS % 60))m"
fi
COST_LABEL="${YELLOW}💰 \$${COST_FMT}${RESET}"
DUR_LABEL="${BLUE}⏳ ${DUR}${RESET}"
DIFF_LABEL="${GREEN}+${LINES_ADD}${RESET}${RED}-${LINES_REM}${RESET}"

# ── Assemble ───────────────────────────────────────────────────────
OUT=""
for PART in "$CAVEMAN" "$FIVE_HR" "$WEEKLY" "$CTX_LABEL" "$EFFORT_LABEL" \
            "$MODEL_LABEL" "$DIFF_LABEL" "$DUR_LABEL" "$COST_LABEL" \
            "$GIT_INFO" "$PROJ" "$VERSION_LABEL"; do
    [ -z "$PART" ] && continue
    if [ -z "$OUT" ]; then OUT="$PART"
    else OUT="${OUT}${SEP}${PART}"
    fi
done

printf '%s' "$OUT"
