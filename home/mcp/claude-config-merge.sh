# shellcheck shell=bash
# (the shebang and `set -euo pipefail` come from writeShellApplication)

# Merge Nix-declared Claude Code configuration into the two files Claude Code
# actually reads.
#
# Neither target can be a `home.file` symlink: Claude Code writes to both at
# runtime (`~/.claude.json` holds project state and history, settings.json holds
# the plugin list, model and TUI mode), and a read-only store symlink makes
# those writes fail. So we merge in place instead.
#
#   ~/.claude.json          <- mcpServers      (user-scope MCP; NOT a settings.json key)
#                              + extra top-level keys (claudeInChromeDefaultEnabled)
#   ~/.claude/settings.json <- statusLine, permissions, plugins
#
# Nix owns the keys it declares and leaves every other key untouched. Servers
# dropped from the Nix config are removed on the next switch, tracked through a
# state file -- without it a merge would strand deleted servers forever.
#
# Arguments: $1 = mcpServers fragment, $2 = settings fragment,
#            $3 = extra ~/.claude.json keys. All JSON files.

MCP_FRAGMENT="$1"
SETTINGS_FRAGMENT="$2"
CLAUDE_JSON_EXTRA="$3"

CLAUDE_JSON="$HOME/.claude.json"
SETTINGS_JSON="$HOME/.claude/settings.json"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nix-home"
STATE_FILE="$STATE_DIR/claude-managed-mcp.json"

mkdir -p "$STATE_DIR" "$HOME/.claude"

# Echo the file if it holds valid JSON, otherwise an empty object. Claude Code
# rewrites these files constantly; a torn write should degrade to "start fresh"
# rather than abort the whole activation.
read_json_or_empty() {
  if [ -s "$1" ] && jq -e . "$1" >/dev/null 2>&1; then
    cat "$1"
  else
    if [ -e "$1" ]; then
      echo "warning: $1 is not valid JSON, rebuilding it" >&2
    fi
    echo '{}'
  fi
}

# Write atomically through a temp file in the *same* directory, so the rename is
# atomic and the result keeps the target filesystem's semantics.
write_atomic() {
  local target="$1" content="$2" tmp
  tmp="$(mktemp "$(dirname "$target")/.$(basename "$target").XXXXXX")"
  printf '%s\n' "$content" >"$tmp"
  if ! jq -e . "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    echo "error: refusing to write invalid JSON to $target" >&2
    return 1
  fi
  if [ -e "$target" ]; then
    # One rolling backup, and inherit the mode we are replacing.
    cp -p "$target" "$target.nix-home.bak"
    chmod --reference="$target" "$tmp"
  else
    chmod 600 "$tmp"
  fi
  mv -f "$tmp" "$target"
}

# --- mcpServers -> ~/.claude.json -------------------------------------------

desired="$(jq -c '.mcpServers // {}' "$MCP_FRAGMENT")"
previous="$(read_json_or_empty "$STATE_FILE" | jq -c 'if type == "array" then . else [] end')"

# Servers this script added last time that Nix no longer declares.
stale="$(jq -cn --argjson prev "$previous" --argjson want "$desired" \
  '$prev - ($want | keys)')"

merged_claude="$(
  read_json_or_empty "$CLAUDE_JSON" | jq \
    --argjson want "$desired" \
    --argjson stale "$stale" \
    --slurpfile extra "$CLAUDE_JSON_EXTRA" \
    '(. * $extra[0]) | .mcpServers = (
       ((.mcpServers // {})
         | with_entries(select(.key as $k | $stale | index($k) | not)))
       * $want
     )'
)"
write_atomic "$CLAUDE_JSON" "$merged_claude"

jq -cn --argjson want "$desired" '$want | keys' >"$STATE_FILE"

# --- statusLine + permissions + plugins -> ~/.claude/settings.json -----------

# `*` merges objects recursively but replaces arrays wholesale, so Nix fully
# owns permissions.allow/deny while keys it does not mention (model, tui,
# permissions.defaultMode, runtime-installed enabledPlugins entries) survive
# untouched.
merged_settings="$(
  read_json_or_empty "$SETTINGS_JSON" | jq -s '.[0] * .[1]' - "$SETTINGS_FRAGMENT"
)"
write_atomic "$SETTINGS_JSON" "$merged_settings"

echo "claude config: mcpServers = $(jq -r '.mcpServers | keys | join(", ")' <<<"$merged_claude")"
