#!/usr/bin/env bash
# Shared helper: record App Store preview after app UI is visible.
# Source from capture scripts; expects PREVIEW_DIR, DEVICE, and ROOT to be set.

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

APP_STORE_PREVIEW_WIDTH="${APP_STORE_PREVIEW_WIDTH:-886}"
APP_STORE_PREVIEW_HEIGHT="${APP_STORE_PREVIEW_HEIGHT:-1920}"

ffmpeg_bin() {
  if command -v ffmpeg >/dev/null 2>&1; then
    command -v ffmpeg
    return
  fi
  if [[ -x /opt/homebrew/bin/ffmpeg ]]; then
    echo /opt/homebrew/bin/ffmpeg
    return
  fi
  echo "ffmpeg not found — install with: brew install ffmpeg" >&2
  return 1
}

detect_leading_black_seconds() {
  local input="$1"
  local ffmpeg stats end
  ffmpeg="$(ffmpeg_bin)" || return 1
  stats="$("$ffmpeg" -hide_banner -i "$input" -vf "blackdetect=d=0.08:pix_th=0.12" -an -f null - 2>&1 || true)"
  end="$(printf '%s\n' "$stats" | awk '
    /black_start:0\.000000/ { want=1 }
    want && /black_end:/ {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^black_end:/) {
          sub(/^black_end:/, "", $i)
          print $i
          exit
        }
      }
    }
  ')"
  if [[ -n "$end" ]]; then
    awk -v t="$end" 'BEGIN { if (t > 0.15 && t < 12) printf "%.3f", t; else print "0" }'
  else
    echo "0"
  fi
}

finalize_preview_video() {
  local raw="$1"
  local final="$2"
  local ffmpeg trim
  ffmpeg="$(ffmpeg_bin)" || return 1

  trim="$(detect_leading_black_seconds "$raw")"
  if awk -v t="$trim" 'BEGIN { exit (t > 0 ? 0 : 1) }'; then
    echo "  Trimming ${trim}s leading black/idle"
  fi

  # App Store App Preview: H.264 High L4.0 @ ~10 Mbps, 30 fps, 886×1920;
  # AAC stereo 48 kHz @ 256 kbps (silent track — simulator capture has no audio).
  "$ffmpeg" -hide_banner -loglevel error -y \
    ${trim:+-ss "$trim"} -i "$raw" \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -map 0:v:0 -map 1:a:0 \
    -vf "scale=${APP_STORE_PREVIEW_WIDTH}:${APP_STORE_PREVIEW_HEIGHT}:force_original_aspect_ratio=increase,crop=${APP_STORE_PREVIEW_WIDTH}:${APP_STORE_PREVIEW_HEIGHT},fps=30" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 -b:v 10M \
    -c:a aac -b:a 256k -ar 48000 -ac 2 \
    -movflags +faststart \
    -shortest \
    "$final"

  local w h dur ab
  w="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$final" 2>/dev/null || echo "?")"
  h="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$final" 2>/dev/null || echo "?")"
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$final" 2>/dev/null || echo "?")"
  ab="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,channels,sample_rate -of csv=p=0 "$final" 2>/dev/null | tr '\n' ' ' || echo "?")"
  echo "  → $final (${w}×${h}, ${dur}s, audio: ${ab:-none}, $(du -h "$final" | awk '{print $1}'))"

  if [[ "$dur" != "?" ]]; then
    awk -v d="$dur" 'BEGIN {
      if (d < 14.5) print "  WARN: preview under 15s — App Store may reject" > "/dev/stderr"
      if (d > 30.5) print "  WARN: preview over 30s — App Store may reject" > "/dev/stderr"
    }'
  fi
}

record_preview() {
  local name="$1"
  local test_file="$2"
  local raw="$PREVIEW_DIR/${name}.mov"
  local final="$PREVIEW_DIR/${name}.mp4"
  local log marker
  log="$(mktemp)"
  marker="$PREVIEW_DIR/.rec_pid_${name}"
  local rec_pid=""

  rm -f "$raw" "$final" "$marker"

  echo "Recording preview: $name"
  cd "$ROOT"

  flutter test "$test_file" -d "$DEVICE" --reporter expanded > >(tee "$log") 2>&1 &
  local test_pid=$!

  start_capture() {
    if [[ -f "$marker" ]]; then
      return
    fi
    echo "  Starting capture"
    sleep 0.35
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
      echo "  Timed out waiting for capture-ready signal" >&2
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

  if [[ ! -f "$raw" ]]; then
    echo "  No video captured for $name" >&2
    return 1
  fi

  finalize_preview_video "$raw" "$final"
  rm -f "$raw"
}
