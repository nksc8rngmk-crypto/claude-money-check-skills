---
name: claim-check
description: Research TikTok/YouTube videos that show trading, crypto, bot or "make money" results and check whether the claims can be verified – finds videos by topic or creator, analyses them, extracts any wallet addresses the creator publicly shows or links, and checks those wallets on-chain (Solana/EVM). Use when the user asks "is this real?", wants creators/videos on a money claim researched, or asks to find/check the wallet behind a profit video.
---

# Claim-Check: Geld-Versprechen in Videos prüfen

Baut auf `tiktok-watch` auf (`~/.claude/skills/tiktok-watch/scripts/watch.sh`). Alle Ausgaben in den Scratchpad.

## Grenze – nicht verhandelbar

Nur Adressen sammeln, die der Creator **selbst öffentlich zeigt oder verlinkt** (Video, Caption, Bio, verlinkte Seiten, öffentliches Trader-Profil auf das er verweist). **Keine** Deanonymisierung: nicht versuchen, verborgene Wallets einer Person zuzuordnen (Clustering, Funding-Spuren zurückverfolgen, Identität hinter einer Wallet ermitteln, Wallets mit Klarnamen/Wohnort verknüpfen). Keine Adressen von Privatpersonen an Dritte weitergeben. Findet sich keine öffentliche Adresse: das ist das Ergebnis („Behauptung nicht belegt“).

## Ablauf

1. **Videos finden**
   - YouTube Stichwort: `bash ~/.claude/skills/claim-check/scripts/search.sh youtube "<suchbegriff>" 10`
   - Videos eines Creators (TikTok oder YouTube): `bash ~/.claude/skills/claim-check/scripts/search.sh user "https://www.tiktok.com/@name" 10`
   - TikTok Stichwortsuche: yt-dlp kann das nicht – WebSearch mit `site:tiktok.com <begriffe>` nutzen.
   Wähle die relevantesten (Views, Thema) und sag dem Nutzer, welche du prüfst.

2. **Jedes Video auswerten**: `watch.sh <url> <scratchpad>/cc-<id>`, dann `sheet.jpg`, `transcript.srt`, `meta.txt` ansehen.

3. **Hinweise extrahieren**: `bash ~/.claude/skills/claim-check/scripts/extract.sh <scratchpad>/cc-<id>`
   OCR (Apple Vision, offline) auf Vollbildern mit 2 fps → `ocr.txt`, dann `findings.txt` mit Solana-/EVM-Adressen, .eth/.sol-Namen, Links, @-Handles.
   `ocr.txt` auch nach Produktnamen, App-Namen, Prozent-/Dollarzahlen durchsuchen (`grep -i`).

4. **Öffentliche Quellen des Creators** (nur was er selbst verlinkt): Profilseite/Bio, Linktree, X-Account, Discord-/Telegram-Einladung, Produktseite. Mit dem Browser lesen (Chrome-Tools, nur lesen, nichts anklicken was beitritt/kauft). Bei Trader-Handles aus dem Video (z. B. Copy-Trading-Apps) das öffentliche Profil der App ansehen.

5. **Wallet prüfen**: `python3 -I ~/.claude/skills/claim-check/scripts/wallet_check.py <adresse> [max_tx]`
   Liefert Saldo, Wallet-Typ, Anzahl/Zeitraum der Transaktionen, Wallet-Alter, Token-Konten und Links zu gmgn.ai / Solscan / Birdeye bzw. DeBank / Etherscan. Für PnL die gmgn.ai-Seite im Browser lesen (`get_page_text`).
   Abgleichen: Passt Zeitraum/Aktivität zur Behauptung im Video? Gab es am behaupteten Tag Trades? Stimmt die Größenordnung?

6. **Bericht** pro Video/Creator:
   - Behauptung (Zahl, Zeitraum, Methode, Produkt)
   - Gefundene öffentliche Belege (Adressen, Links) – oder „keine“
   - On-Chain-Befund und ob er die Behauptung stützt
   - Warnzeichen (keine Belege, Ref-Links, Discord-Funnel, gleiche UI bei mehreren Accounts, Reichweiten-Tricks)
   - Urteil: **belegt / teilweise belegt / nicht belegt / widerlegt** – nie „Betrug“ behaupten ohne Beweis, sondern was die Daten zeigen.

## Verlinkte Tools/Repos prüfen (nur lesen, nie ausführen)
- GitHub-Repo: Alter (`curl -s https://api.github.com/repos/<owner>/<repo>`), README, `.env.example`. Achten auf: Demo-/Paper-/Simulationsmodus (sind die Video-Zahlen echt oder simuliert?), Referral-Parameter (verdient der Creator an deinen Trades?), eingebaute „Share-Card“/Post-Generatoren, Forderung nach `PRIVATE_KEY`/Seed-Phrase.
- Im `ocr.txt` nach Modus-Labels suchen: `grep -i -w -E "paper|demo|sim|simulated|live|testnet" ocr.txt`.
- Nutzer nie dazu raten, einen Private Key in ungeprüften Code einzutragen.

## Hinweise
- Öffentliche Solana-RPC ist rate-limitiert; das Script wartet bei 429. Für sehr aktive Wallets `max_tx` klein lassen (Standard 1000).
- Ein einzelner hoher Gewinn auf einer Wallet beweist keine Strategie – Zeitraum und Verluste ansehen.
- Wallet gehört evtl. nicht dem Creator (z. B. fremde Trader-Wallet, die er kopiert) – so benennen.
