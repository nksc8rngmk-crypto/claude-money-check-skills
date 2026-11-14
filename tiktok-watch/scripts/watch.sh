#!/usr/bin/env bash
# Usage: watch.sh <tiktok-url-or-local-video> [out-dir] [fps]
# Downloads a video, extracts frames and transcribes the audio.
set -euo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

SRC="${1:?Bitte TikTok-Link oder Videodatei angeben}"
OUT="${2:-$(mktemp -d "${TMPDIR:-/tmp}/tiktok-watch.XXXXXX")}"
FPS="${3:-1}"
mkdir -p "$OUT/frames"

# 1. Download (or copy local file)
if [[ -f "$SRC" ]]; then
  cp "$SRC" "$OUT/video.mp4"
else
  yt-dlp -q --no-warnings --no-playlist -f "mp4/best" \
    --write-info-json -o "$OUT/video.%(ext)s" "$SRC"
  [[ -f "$OUT/video.mp4" ]] || mv "$OUT"/video.* "$OUT/video.mp4" 2>/dev/null || true
  # Slim metadata summary
  python3 -I - "$OUT/video.info.json" > "$OUT/meta.txt" <<'PY' || true
import json, sys
d = json.load(open(sys.argv[1]))
for k in ("title","uploader","channel","upload_date","duration","view_count",
          "like_count","comment_count","repost_count","webpage_url","description"):
    if d.get(k) is not None: print(f"{k}: {d[k]}")
tags = d.get("tags") or []
if tags: print("tags:", ", ".join(tags))
if d.get("track") or d.get("artist"): print(f"sound: {d.get('track')} – {d.get('artist')}")
PY
fi

# 2. Frames (max width 512 to keep images small)
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/video.mp4" | cut -d. -f1)
# Long videos: cap at ~40 frames
if [[ "${DUR:-0}" -gt 40 && "$FPS" == "1" ]]; then FPS=$(python3 -c "print(40/$DUR)"); fi
ffmpeg -v error -i "$OUT/video.mp4" -vf "fps=$FPS,scale='min(512,iw)':-2" -q:v 4 "$OUT/frames/f_%03d.jpg"

# Contact sheet: all frames on one image (6 columns), quick overview
N=$(ls "$OUT/frames" | wc -l | tr -d ' '); ROWS=$(( (N + 5) / 6 ))
ffmpeg -v error -y -pattern_type glob -i "$OUT/frames/*.jpg" \
  -vf "scale=256:-2,tile=6x${ROWS}" -frames:v 1 "$OUT/sheet.jpg" || true

# 3. Transcript (skipped if no audio stream)
if ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$OUT/video.mp4" | grep -q .; then
  ffmpeg -v error -i "$OUT/video.mp4" -vn -ac 1 -ar 16000 "$OUT/audio.wav"
  mlx_whisper "$OUT/audio.wav" --model "${WHISPER_MODEL:-mlx-community/whisper-large-v3-turbo}" \
    --output-dir "$OUT" --output-name transcript --output-format srt >/dev/null 2>&1 \
    || echo "(Transkription fehlgeschlagen)" > "$OUT/transcript.srt"
else
  echo "(kein Ton)" > "$OUT/transcript.srt"
fi

echo "OUT=$OUT"
echo "DURATION=${DUR}s FRAMES=$(ls "$OUT/frames" | wc -l | tr -d ' ') FPS=$FPS"
