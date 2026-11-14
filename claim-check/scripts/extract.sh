#!/usr/bin/env bash
# Usage: extract.sh <video-dir-from-tiktok-watch>
# OCRs full-resolution frames, then scans OCR text + metadata for wallet
# addresses, links and social handles. Writes ocr.txt and findings.txt.
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
DIR="${1:?tiktok-watch output dir}"
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/.ocr-bin"
[[ -x "$BIN" && "$BIN" -nt "$HERE/ocr.swift" ]] || swiftc -O -o "$BIN" "$HERE/ocr.swift" 2>/dev/null

mkdir -p "$DIR/ocr_frames"
# 2 fps at full resolution – addresses are small text
ffmpeg -v error -y -i "$DIR/video.mp4" -vf fps=2 -q:v 2 "$DIR/ocr_frames/o_%03d.jpg"
"$BIN" "$DIR"/ocr_frames/*.jpg > "$DIR/ocr.txt" || true

python3 -I "$HERE/find_addresses.py" "$DIR/ocr.txt" "$DIR/meta.txt" "$DIR/video.info.json" > "$DIR/findings.txt"
cat "$DIR/findings.txt"
