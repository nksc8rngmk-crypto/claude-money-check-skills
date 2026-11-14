# Is this TikTok real? – Claude Code skills

Two [Claude Code](https://claude.com/claude-code) skills that let Claude **watch TikToks** and **check money claims** ("my bot made +2,200 % overnight").

| Skill | What it does |
|---|---|
| `tiktok-watch` | Downloads a public TikTok, splits it into frames, a contact sheet, a Whisper transcript and metadata, so Claude can "see" and "hear" the video. |
| `claim-check` | Finds trading/crypto/"make money" videos on a topic or creator, pulls wallet addresses shown on screen (OCR) or in the caption, and checks those wallets on-chain (Solana / EVM). |

Skill texts are in German; Claude answers in your language.

## Example
> **You:** Is this real? https://www.tiktok.com/@…/video/…
>
> **Claude:** Screen recording of a memecoin bot, $89 → $2,064 overnight. No wallet shown, "DM me" in the overlay → typical affiliate bait, not verifiable.

## Install (macOS)
```bash
brew install ffmpeg yt-dlp
uv tool install mlx-whisper          # local transcription, Apple Silicon
git clone https://github.com/nksc8rngmk-crypto/claude-money-check-skills
cp -R claude-money-check-skills/tiktok-watch claude-money-check-skills/claim-check ~/.claude/skills/
```
Then in Claude Code: `/tiktok-watch <url>` or just ask "is this video real?".

## Limits
- Public videos only; TikTok photo posts give only the cover image.
- Comments are not loaded (TikTok blocks them without login).
- Profit numbers on screen can't be verified – only wallets can.
- Not financial advice.

## License
MIT
