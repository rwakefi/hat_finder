#!/usr/bin/env bash
# Auto hot-restart Flutter web when lib/ or web/ changes.
# Uses Chrome so the browser tab refreshes without Cmd+Shift+R.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${FLUTTER_ROOT:-$HOME/development/flutter}/bin/flutter"
PID_FILE="$ROOT/.dart_tool/flutter_dev.pid"
PORT=8081

cd "$ROOT"

if [[ ! -x "$FLUTTER" ]]; then
  echo "Flutter not found at $FLUTTER"
  exit 1
fi

echo "Stopping any existing server on :$PORT..."
lsof -ti :"$PORT" | xargs kill -9 2>/dev/null || true
sleep 1

mkdir -p "$ROOT/.dart_tool"
rm -f "$PID_FILE"

echo "Starting Flutter on Chrome at http://127.0.0.1:$PORT"
"$FLUTTER" run -d chrome \
  --web-hostname=127.0.0.1 \
  --web-port="$PORT" \
  --pid-file="$PID_FILE" &

RUN_PID=$!

cleanup() {
  kill "$RUN_PID" 2>/dev/null || true
  lsof -ti :"$PORT" | xargs kill -9 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Waiting for Flutter dev server..."
for _ in $(seq 1 120); do
  [[ -f "$PID_FILE" ]] && break
  sleep 1
done

if [[ ! -f "$PID_FILE" ]]; then
  echo "Flutter did not write pid file — check errors above."
  wait "$RUN_PID" || true
  exit 1
fi

FLUTTER_PID="$(cat "$PID_FILE")"
echo "Watching lib/ and web/ — saves trigger hot restart (PID $FLUTTER_PID)"
echo "Open http://127.0.0.1:$PORT in Chrome (Flutter may open it for you)."

checksum() {
  find "$ROOT/lib" "$ROOT/web" -type f \( -name '*.dart' -o -name '*.html' \) -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null \
    | shasum -a 256 \
    | awk '{print $1}'
}

LAST="$(checksum || true)"
while kill -0 "$RUN_PID" 2>/dev/null; do
  sleep 2
  CUR="$(checksum || true)"
  if [[ -n "$CUR" && "$CUR" != "$LAST" ]]; then
    LAST="$CUR"
    if kill -0 "$FLUTTER_PID" 2>/dev/null; then
      echo "$(date '+%H:%M:%S') Change detected — hot restarting..."
      kill -USR2 "$FLUTTER_PID" 2>/dev/null || true
    fi
  fi
done

wait "$RUN_PID" || true
