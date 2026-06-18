#!/usr/bin/env bash
# Capture iPhone simulator screenshot and resize for App Store "6.5 inch" slot.
# Usage: ./scripts/app_store_screenshot.sh 02-hat-type
# Navigate to the screen in Simulator first, then run this script.

set -euo pipefail

NAME="${1:?Usage: app_store_screenshot.sh <name> (e.g. 02-hat-type)}"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/artifacts/screenshots/app-store/6.5-inch"
mkdir -p "$OUT_DIR"

RAW="$OUT_DIR/${NAME}-raw.png"
FINAL="$OUT_DIR/${NAME}.png"

xcrun simctl io booted screenshot "$RAW"
# iPhone 16 Plus → App Store 6.5" portrait (1284 × 2778)
sips -z 2778 1284 "$RAW" --out "$FINAL" >/dev/null

echo "Saved $FINAL ($(sips -g pixelWidth -g pixelHeight "$FINAL" | awk '/pixel/ {print $2}' | tr '\n' x | sed 's/x$//'))"
