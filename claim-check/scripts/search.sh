#!/usr/bin/env bash
# Usage:
#   search.sh youtube "<query>" [N]        – YouTube keyword search
#   search.sh user <tiktok-or-youtube-profile-url> [N] – latest videos of a creator
# Output: one line per video: url | title | channel | views | upload_date
set -euo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
MODE="${1:?mode: youtube|user}"; Q="${2:?query or profile url}"; N="${3:-10}"
FMT='%(webpage_url|url)s | %(title).90s | %(channel|uploader)s | %(view_count)s views | %(upload_date)s'
case "$MODE" in
  youtube) yt-dlp --flat-playlist --no-warnings --print "$FMT" "ytsearch${N}:${Q}" ;;
  user)    yt-dlp --flat-playlist --no-warnings --playlist-end "$N" --print "$FMT" "$Q" ;;
  *) echo "unknown mode $MODE" >&2; exit 1 ;;
esac
