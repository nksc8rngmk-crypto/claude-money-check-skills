---
name: tiktok-watch
description: "Watch" a TikTok (or any yt-dlp-supported video like Instagram Reels, YouTube Shorts, or a local video file) by downloading it, extracting frames and transcribing the audio, then describing or analysing it. Use when the user shares a TikTok/Reel/Shorts link or video file and asks what's in it, to summarise it, analyse it, or "schau dir das TikTok an".
---

# TikTok ansehen

Claude kann Videos nicht direkt abspielen. Dieser Skill zerlegt das Video in Standbilder, Transkript und Metadaten.

## Ablauf

1. Script ausführen (Ausgabeordner im Scratchpad wählen):
   ```bash
   bash ~/.claude/skills/tiktok-watch/scripts/watch.sh "<URL oder Datei>" "<scratchpad>/tiktok-<id>"
   ```
   Optionaler 3. Parameter: Bilder pro Sekunde (Standard 1, bei Videos >40 s automatisch auf ~40 Bilder begrenzt). Für schnelle Schnitte z. B. `2` übergeben.
   Erster Lauf lädt das Whisper-Modell (~1,5 GB) – dauert einmalig etwas. Bei Bedarf `run_in_background` nutzen.

2. Ergebnisse im Ausgabeordner lesen:
   - `meta.txt` – Titel/Caption, Creator, Datum, Views, Likes, Kommentare, Hashtags, Sound
   - `transcript.srt` – gesprochener Text mit Zeitstempeln
   - `sheet.jpg` – alle Bilder als Raster (6 pro Zeile, zeilenweise chronologisch). Zuerst das ansehen; einzelne Frames nur lesen, wenn Text zu klein ist.
   - `frames/f_001.jpg …` – ein Bild pro Sekunde (f_001 ≈ Sekunde 0). Mit dem Read-Tool ansehen; bei vielen Bildern mehrere parallel lesen.

3. Antwort an den Nutzer: Was passiert visuell (in zeitlicher Reihenfolge), was wird gesagt, eingeblendeter Text, Caption/Hashtags, Kennzahlen. Dann auf die eigentliche Frage des Nutzers eingehen.

## Grenzen (offen sagen)

- Nur öffentliche Videos; private oder login-pflichtige schlagen fehl.
- Bewegung zwischen den Bildern und Musik ohne Gesang werden nicht erfasst – nur der Name des Sounds aus den Metadaten.
- Fotoslideshows (TikTok-„Fotos“) lädt yt-dlp evtl. nur als Audio; dann Fehlermeldung zeigen.
- Kommentare werden nicht geladen (yt-dlp liefert für TikTok ohne Login 0 Kommentare – getestet Nov. 2026).
- Bei Bildschirmaufnahmen mit Geld-/Gewinnzahlen: Zahlen sind nicht nachprüfbar – das in der Bewertung erwähnen.

## Fehler

- `yt-dlp` veraltet (TikTok ändert oft die API): `brew upgrade yt-dlp`, dann erneut versuchen.
- Werkzeuge fehlen: `brew install ffmpeg yt-dlp` und `uv tool install mlx-whisper`.
