#!/usr/bin/env bash
# Claude Code statusline. Consumes stdin JSON from Claude Code.
# Prints only the context window; Claude's own footer shows the permission mode (the payload has no field for it).
# Side effect: shares the account-wide rate limits with the overbridge sidebar, which shows them instead.
# Pure-bash JSON extraction (no jq) for speed.

set -u

CYAN=$'\033[38;5;39m'
YELLOW=$'\033[38;5;226m'
RED=$'\033[38;5;203m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

printf -v NOW '%(%s)T' -1
INPUT=$(cat)

CTX_PCT=0; FH_PCT=0; WK_PCT=0; FH_RESET=0; WK_RESET=0
# context_window nests current_usage{} before used_percentage; allow one level.
_re='"context_window":\{([^{}]|\{[^{}]*\})*"used_percentage":([0-9]+)'; [[ $INPUT =~ $_re ]] && CTX_PCT="${BASH_REMATCH[2]}"
_re='"five_hour":\{[^}]*"used_percentage":([0-9]+)';     [[ $INPUT =~ $_re ]] && FH_PCT="${BASH_REMATCH[1]}"
_re='"five_hour":\{[^}]*"resets_at":([0-9]+)';           [[ $INPUT =~ $_re ]] && FH_RESET="${BASH_REMATCH[1]}"
_re='"seven_day":\{[^}]*"used_percentage":([0-9]+)';     [[ $INPUT =~ $_re ]] && WK_PCT="${BASH_REMATCH[1]}"
_re='"seven_day":\{[^}]*"resets_at":([0-9]+)';           [[ $INPUT =~ $_re ]] && WK_RESET="${BASH_REMATCH[1]}"

# Share the account-wide limits with the overbridge sidebar (only inside an overbridge workspace).
if [ -n "${OVERBRIDGE_ROOT:-}" ] && { [ "$FH_RESET" -gt 0 ] || [ "$WK_RESET" -gt 0 ]; } && [ -d "$OVERBRIDGE_ROOT/.overbridge" ]; then
    _lf="$OVERBRIDGE_ROOT/.overbridge/limits.json"
    printf '{"at":%s000,"fiveHour":{"pct":%s,"resetsAt":%s},"weekly":{"pct":%s,"resetsAt":%s}}\n' \
        "$NOW" "$FH_PCT" "$FH_RESET" "$WK_PCT" "$WK_RESET" >"$_lf.$$" 2>/dev/null && mv -f "$_lf.$$" "$_lf" 2>/dev/null
fi

# Context: warn from 20% used.
if [ "$CTX_PCT" -ge 50 ]; then printf '%s' "${RED}${BOLD}🪟 ${CTX_PCT}% ⚠${RESET}"
elif [ "$CTX_PCT" -ge 20 ]; then printf '%s' "${YELLOW}🪟 ${CTX_PCT}% ⚠${RESET}"
else printf '%s' "${CYAN}🪟 ${CTX_PCT}%${RESET}"
fi
