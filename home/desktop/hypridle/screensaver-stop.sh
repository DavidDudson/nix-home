#!/usr/bin/env bash
# Stop mpvpaper screensaver.
set -euo pipefail
pkill -x mpvpaper || true
