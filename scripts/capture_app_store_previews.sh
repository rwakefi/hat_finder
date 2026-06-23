#!/usr/bin/env bash
# Record 3 App Store preview videos — starts capture only after the app is on screen.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${APP_STORE_DEVICE:-ACD45376-84BA-4DE6-9728-4CCACB7F09AD}"
PREVIEW_DIR="$ROOT/artifacts/screenshots/app-store/6.5-inch/previews"

mkdir -p "$PREVIEW_DIR"
# shellcheck source=app_store_record_preview.sh
source "$ROOT/scripts/app_store_record_preview.sh"

echo "== App Store preview capture (iPhone 6.5\") =="
echo "Device: $DEVICE"
echo "Export: ${APP_STORE_PREVIEW_WIDTH:-886}×${APP_STORE_PREVIEW_HEIGHT:-1920} portrait (App Store 6.5\")"
echo ""

xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator 2>/dev/null || true

cd "$ROOT"
flutter pub get >/dev/null
echo "Warming simulator build + install…"
flutter build ios --simulator --debug --no-pub
flutter install -d "$DEVICE" --no-pub 2>/dev/null || true
sleep 2

record_preview "preview-1-intro" "integration_test/app_store_preview_1_test.dart"
sleep 2
record_preview "preview-2-wizard" "integration_test/app_store_preview_2_test.dart"
sleep 2
record_preview "preview-3-learn" "integration_test/app_store_preview_3_test.dart"

echo ""
echo "Done. Previews: $PREVIEW_DIR"
open "$PREVIEW_DIR"
