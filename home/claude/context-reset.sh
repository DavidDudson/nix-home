#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook. Once the session's context passes
# CLAUDE_CONTEXT_RESET_PCT (default 20), tell Claude to wrap up and recommend a
# reset. statusline.sh records the context % per session; this reads it.

set -u

THRESHOLD="${CLAUDE_CONTEXT_RESET_PCT:-20}"
INPUT=$(cat)

_re='"session_id":"([^"]+)"'
[[ $INPUT =~ $_re ]] || exit 0
CTX_FILE="${XDG_RUNTIME_DIR:-/tmp}/claude-ctx/${BASH_REMATCH[1]}"
[ -f "$CTX_FILE" ] || exit 0
PCT=$(<"$CTX_FILE")
[[ $PCT =~ ^[0-9]+$ ]] || exit 0
[ "$PCT" -ge "$THRESHOLD" ] || exit 0

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Context is at ${PCT}% (reset threshold ${THRESHOLD}%). Finish the current step only; do not start new work. Then give a short handoff (state, next step, files and branches involved) the user can paste into a fresh session, and recommend /clear."}}
EOF
