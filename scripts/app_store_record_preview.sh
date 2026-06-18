#!/usr/bin/env bash
# Shared helper: record App Store preview after app UI is visible.
# Source from capture scripts; expects PREVIEW_DIR, DEVICE, and ROOT to be set.

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

record_preview() {
  local name="$1"
  local test_file="$2"
  local raw="$PREVIEW_DIR/${name}.mov"
  local final="$PREVIEW_DIR/${name}.mp4"
  local log marker
  log="$(mktemp)"
  marker="$PREVIEW_DIR/.rec_pid_${name}"
  local rec_pid=""

  rm -f "$marker"

  echo "Recording preview: $name"
  cd "$ROOT"

  flutter test "$test_file" -d "$DEVICE" --reporter expanded > >(tee "$log") 2>&1 &
  local test_pid=$!

  start_capture() {
    if [[ -f "$marker" ]]; then
      return
    fi
    echo "  Starting capture"
    sleep 0.5
    xcrun simctl io "$DEVICE" recordVideo "$raw" &
    rec_pid=$!
    echo "$rec_pid" > "$marker"
  }

  local waited=0
  while kill -0 "$test_pid" 2>/dev/null; do
    if [[ -f "$marker" ]]; then
      rec_pid="$(cat "$marker")"
      break
    fi
    if grep -qF "+0: capture ready" "$log" 2>/dev/null; then
      echo "  App visible — starting capture"
      start_capture
      break
    fi
    sleep 1
    waited=$((waited + 1))
    if [[ $waited -ge 300 ]]; then
      kill "$test_pid" 2>/dev/null || true
      break
    fi
  done

  wait "$test_pid"
  local test_status=$?
  cat "$log"
  rm -f "$log" "$marker"

  if [[ -n "$rec_pid" ]]; then
    sleep 0.5
    kill -INT "$rec_pid" 2>/dev/null || true
    wait "$rec_pid" 2>/dev/null || true
  fi

  if [[ $test_status -ne 0 ]]; then
    return 1
  fi

  if [[ -f "$raw" ]]; then
    /usr/bin/avconvert --preset Preset1280x720 --source "$raw" --output "$final" --replace 2>/dev/null \
      || cp "$raw" "$final"
    rm -f "$raw"
    echo "  → $final ($(du -h "$final" | awk '{print $1}'))"
  else
    echo "  No video captured for $name" >&2
    return 1
  fi
}
