#!/usr/bin/env bash
# Waybar quote module: pulls a fresh one-liner from icanhazdadjoke.com every
# 5 minutes, scrolling the text through a fixed window each tick. Network
# fetches run in the background so they never block waybar's polling loop.
# Falls back to the bundled quotes file if the API is unreachable.

# NOTE: pipefail intentionally omitted — see memory.sh for SIGPIPE rationale.
set -eu

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/waybar-quote"
mkdir -p "$cache_dir"
cache="$cache_dir/current"
fallback="$HOME/.local/share/waybar-quotes.txt"

now=$(date +%s)
refresh_secs=300

# Decide whether the cached quote is stale and kick off a background fetch
# if so. The fetch never blocks — waybar still gets an immediate response
# from the existing cache (or fallback) on this tick.
needs_fetch=true
if [ -f "$cache" ]; then
    age=$(( now - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
    [ "$age" -lt "$refresh_secs" ] && needs_fetch=false
fi

if $needs_fetch; then
    (
        new=$(timeout 5 curl -fsS \
            -H 'Accept: application/json' \
            -H 'User-Agent: waybar-quote (https://github.com/davidjdudson)' \
            https://icanhazdadjoke.com/ 2>/dev/null \
            | jq -r '.joke // empty' 2>/dev/null) || true
        new=${new//$'\n'/ }
        new=${new//$'\r'/ }
        if [ -n "${new:-}" ]; then
            printf '%s\n' "$new" > "$cache.tmp" && mv "$cache.tmp" "$cache"
        else
            # Fetch failed: bump mtime so we wait another full refresh_secs
            # before retrying instead of hammering the API every tick.
            [ -f "$cache" ] && touch "$cache"
        fi
    ) >/dev/null 2>&1 &
fi

# Choose quote source: live cache wins; static fallback covers cold start
# and offline scenarios.
quote=""
if [ -s "$cache" ]; then
    quote=$(head -1 "$cache")
elif [ -f "$fallback" ]; then
    mapfile -t quotes < "$fallback"
    if [ "${#quotes[@]}" -gt 0 ]; then
        qidx=$(( (now / refresh_secs) % ${#quotes[@]} ))
        quote="${quotes[$qidx]}"
    fi
fi
quote=${quote:-...}

# Scroll buffer: triple-padded so substring extraction never overruns.
window=60
char_period_ms=300
now_ms=$(date +%s%3N)
pad="    "
buf="${quote}${pad}${quote}${pad}${quote}${pad}"
unit=$(( ${#quote} + ${#pad} ))
[ "$unit" -gt 0 ] || unit=1
offset=$(( (now_ms / char_period_ms) % unit ))
text="${buf:offset:window}"

jq -cn --arg text "$text" '{text: $text}'
