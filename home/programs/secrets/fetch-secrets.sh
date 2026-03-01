#!/usr/bin/env bash
# Fetch secrets from 1Password and cache to a JSON file.
# Run once at session start; all terminals load from the cache.

SECRETS_DIR="$HOME/.config/secrets"
SECRETS_FILE="$SECRETS_DIR/secrets.json"

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

PIXELLAB_API_KEY=$(op read "op://Private/PixelLab/credential" 2>/dev/null || echo "")

cat > "$SECRETS_FILE" <<EOF
{
  "PIXELLAB_API_KEY": "$PIXELLAB_API_KEY"
}
EOF

chmod 600 "$SECRETS_FILE"
