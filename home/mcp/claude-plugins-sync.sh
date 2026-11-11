# shellcheck shell=bash
# (the shebang and `set -euo pipefail` come from writeShellApplication)

# Force-install and force-update the Claude Code plugins Nix guarantees.
#
# settings.json only *declares* the marketplaces and enabled plugins; Claude
# Code fetches them lazily. This runs on every switch so a bumped overbridge
# lands in the installed plugin cache straight away instead of at some later
# session start.
#
# Best effort: a missing `claude` binary or no network warns and exits 0, so
# a switch never fails on it.
#
# Arguments: $1 = JSON file {marketplaces: {name: source}, plugins: [id]}.

SPEC="$1"

# Activation runs with a minimal PATH; claude lives in the user profile.
PATH="/etc/profiles/per-user/${USER:-$(id -un)}/bin:/run/current-system/sw/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:$PATH"

if ! command -v claude >/dev/null 2>&1; then
  echo "warning: claude not found, skipping plugin sync" >&2
  exit 0
fi

failed=0
warn() {
  echo "warning: $*" >&2
  failed=1
}

known="$(claude plugin marketplace list --json 2>/dev/null || echo '[]')"

# Marketplaces: (re)register any that are missing or point somewhere else.
# A directory source moves with every overbridge bump, so replace it.
while IFS=$'\t' read -r name source; do
  current="$(jq -r --arg n "$name" \
    '.[] | select(.name == $n) | (.path // .repo // .url // "")' <<<"$known" | head -n1)"
  if [ "$current" != "$source" ]; then
    if [ -n "$current" ]; then
      claude plugin marketplace remove "$name" >/dev/null 2>&1 ||
        warn "could not remove stale marketplace $name"
    fi
    claude plugin marketplace add "$source" >/dev/null ||
      warn "could not add marketplace $name ($source)"
  fi
done < <(jq -r '.marketplaces | to_entries[] | [.key, .value] | @tsv' "$SPEC")

claude plugin marketplace update >/dev/null 2>&1 || warn "marketplace update failed"

# Plugins: install is a no-op when present, update pulls the latest version.
while read -r plugin; do
  claude plugin install --scope user "$plugin" >/dev/null 2>&1 ||
    warn "could not install $plugin"
  claude plugin update --scope user "$plugin" >/dev/null 2>&1 ||
    warn "could not update $plugin"
done < <(jq -r '.plugins[]' "$SPEC")

if [ "$failed" -eq 0 ]; then
  echo "claude plugins: synced $(jq -r '.plugins | join(", ")' "$SPEC")"
fi
