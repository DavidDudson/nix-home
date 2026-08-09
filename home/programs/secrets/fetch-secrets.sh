#!/usr/bin/env bash
# Fetch secrets from 1Password and cache to disk.
# Run once at session start; all terminals load from the cache.

SECRETS_DIR="$HOME/.config/secrets"
SECRETS_FILE="$SECRETS_DIR/secrets.json"

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

PIXELLAB_API_KEY=$(op read "op://Private/PixelLab/credential" 2>/dev/null || echo "")
WALLHAVEN_API_KEY=$(op read "op://Private/Wallhaven API Key/credential" 2>/dev/null || echo "")

cat > "$SECRETS_FILE" <<EOF
{
  "PIXELLAB_API_KEY": "$PIXELLAB_API_KEY",
  "WALLHAVEN_API_KEY": "$WALLHAVEN_API_KEY"
}
EOF
chmod 600 "$SECRETS_FILE"

# Variety reads its config (and api key) on launch, not from JSON — write a
# plain-text file the variety-theme wrapper can splice into the active profile.
if [ -n "$WALLHAVEN_API_KEY" ]; then
    printf '%s' "$WALLHAVEN_API_KEY" > "$SECRETS_DIR/wallhaven_api_key"
    chmod 600 "$SECRETS_DIR/wallhaven_api_key"
fi
