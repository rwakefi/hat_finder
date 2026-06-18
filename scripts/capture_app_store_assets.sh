#!/usr/bin/env bash
# Capture App Store assets for iPhone 6.5" Display (1284×2778 screenshots + 3 previews).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${APP_STORE_DEVICE:-ACD45376-84BA-4DE6-9728-4CCACB7F09AD}"
SHOT_DIR="$ROOT/artifacts/screenshots/app-store/6.5-inch"
PREVIEW_DIR="$ROOT/artifacts/screenshots/app-store/6.5-inch/previews"

mkdir -p "$SHOT_DIR" "$PREVIEW_DIR"
# shellcheck source=app_store_record_preview.sh
source "$ROOT/scripts/app_store_record_preview.sh"

resize_screenshot() {
  local file="$1"
  local tmp="${file}.resizing.png"
  cp "$file" "$tmp"
  sips -z 2778 1284 "$tmp" --out "$file" >/dev/null
  rm -f "$tmp"
  echo "  → $(basename "$file") $(sips -g pixelWidth -g pixelHeight "$file" | awk '/pixel/ {printf "%s ", $2} END {print ""}')"
}

echo "== App Store asset capture (iPhone 6.5\") =="
echo "Device: $DEVICE"
echo ""

cd "$ROOT"
flutter pub get >/dev/null

echo "Capturing 10 screenshots…"
flutter drive \
  --driver=test_driver/app_store_integration_test.dart \
  --target=integration_test/app_store_screenshots_test.dart \
  -d "$DEVICE" \
  --no-pub

echo ""
echo "Resizing screenshots to 1284×2778…"
for i in $(seq -w 1 10); do
  case "$i" in
    01) f="$SHOT_DIR/01-home.png" ;;
    02) f="$SHOT_DIR/02-hat-type.png" ;;
    03) f="$SHOT_DIR/03-style.png" ;;
    04) f="$SHOT_DIR/04-crown.png" ;;
    05) f="$SHOT_DIR/05-brim.png" ;;
    06) f="$SHOT_DIR/06-results.png" ;;
    07) f="$SHOT_DIR/07-head-shape.png" ;;
    08) f="$SHOT_DIR/08-crown-guide.png" ;;
    09) f="$SHOT_DIR/09-brim-guide.png" ;;
    10) f="$SHOT_DIR/10-events-connect.png" ;;
  esac
  if [[ -f "$f" ]]; then
    resize_screenshot "$f"
  else
    echo "  MISSING: $f" >&2
  fi
done

echo ""
echo "Recording 3 app previews…"
echo "Warming simulator build (one-time)…"
flutter build ios --simulator --debug --no-pub >/dev/null 2>&1 || true
record_preview "preview-1-intro" "integration_test/app_store_preview_1_test.dart" 130
record_preview "preview-2-wizard" "integration_test/app_store_preview_2_test.dart" 45
record_preview "preview-3-learn" "integration_test/app_store_preview_3_test.dart" 45

echo ""
echo "Done."
echo "Screenshots: $SHOT_DIR"
echo "Previews:    $PREVIEW_DIR"
echo ""
echo "In App Store Connect → iPhone 6.5\" Display:"
echo "  • Drag 01-home.png … 10-events-connect.png into Screenshots"
echo "  • Upload preview-1-intro.mp4, preview-2-wizard.mp4, preview-3-learn.mp4 into App Previews"
