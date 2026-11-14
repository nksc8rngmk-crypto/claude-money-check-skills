#!/usr/bin/env bash
# Usage: transcript.sh <youtube-url> <out-dir> [lang=en]
# Fast transcript for long talk videos: uses YouTube subtitles (manual first, then auto),
# falls back to local Whisper on the audio. Writes transcript.txt (deduplicated plain text,
# with a [mm:ss] marker roughly every minute) and meta.txt.
set -euo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
URL="${1:?url}"; OUT="${2:?out dir}"; LANG_="${3:-en}"
mkdir -p "$OUT"

yt-dlp -q --no-warnings --skip-download --write-info-json \
  --write-subs --write-auto-subs --sub-langs "${LANG_}.*,${LANG_}" --sub-format vtt \
  -o "$OUT/v.%(ext)s" "$URL" || true

python3 -I - "$OUT" <<'PY'
import glob, json, os, re, sys
out = sys.argv[1]
info = glob.glob(os.path.join(out, "v.info.json"))
if info:
    d = json.load(open(info[0]))
    with open(os.path.join(out, "meta.txt"), "w") as f:
        for k in ("title", "channel", "upload_date", "duration_string", "view_count", "webpage_url"):
            if d.get(k) is not None: f.write(f"{k}: {d[k]}\n")
        f.write("description: " + (d.get("description") or "")[:1500] + "\n")
vtts = sorted(glob.glob(os.path.join(out, "v.*.vtt")), key=lambda p: ("orig" not in p, "-" in os.path.basename(p)[2:], p))
if not vtts: sys.exit(0)
lines, last, mark = [], None, -60
t = 0
for raw in open(vtts[0], encoding="utf-8", errors="ignore"):
    m = re.match(r"(\d+):(\d+):(\d+)\.\d+ -->", raw)
    if m:
        t = int(m[1]) * 3600 + int(m[2]) * 60 + int(m[3]); continue
    s = re.sub(r"<[^>]+>", "", raw).strip()
    if not s or s.startswith(("WEBVTT", "Kind:", "Language:", "NOTE")) or s == last: continue
    if lines and s in lines[-1]: continue
    last = s
    if t - mark >= 60:
        lines.append(f"\n[{t//60:02d}:{t%60:02d}] "); mark = t
    lines.append(s)
text = " ".join(lines)
text = re.sub(r"\b(\w+(?: \w+){0,6}) \1\b", r"\1", text)   # rolling auto-sub duplicates
open(os.path.join(out, "transcript.txt"), "w").write(text)
PY

if [[ ! -s "$OUT/transcript.txt" ]]; then
  echo "no subtitles – falling back to Whisper" >&2
  yt-dlp -q --no-warnings -x --audio-format wav --postprocessor-args "-ac 1 -ar 16000" -o "$OUT/audio.%(ext)s" "$URL"
  mlx_whisper "$OUT/audio.wav" --model "${WHISPER_MODEL:-mlx-community/whisper-large-v3-turbo}" \
    --output-dir "$OUT" --output-name transcript --output-format txt >/dev/null 2>&1
fi
echo "OUT=$OUT WORDS=$(wc -w < "$OUT/transcript.txt" | tr -d ' ')"
