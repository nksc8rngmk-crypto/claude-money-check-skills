"""Scan text files for crypto wallet addresses, links and social handles.
Usage: python3 -I find_addresses.py <file>... """
import json, re, sys
from pathlib import Path

B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58decode_len(s):
    n = 0
    for c in s:
        n = n * 58 + B58.index(c)
    raw = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    return len(raw) + (len(s) - len(s.lstrip("1")))

def is_solana(s):
    try:
        return b58decode_len(s) == 32
    except ValueError:
        return False

text = ""
for f in sys.argv[1:]:
    p = Path(f)
    if not p.exists():
        continue
    t = p.read_text(errors="ignore")
    if p.suffix == ".json":
        try:
            d = json.loads(t)
            t = "\n".join(str(d.get(k, "")) for k in ("description", "title", "uploader", "channel_url", "uploader_url"))
        except Exception:
            pass
    text += "\n" + t

# OCR often splits addresses with spaces/line breaks – also check joined lines
joined = re.sub(r"[ \t]", "", text)

sol = sorted({m for src in (text, joined)
              for m in re.findall(r"(?<![1-9A-HJ-NP-Za-km-z])[1-9A-HJ-NP-Za-km-z]{32,44}(?![1-9A-HJ-NP-Za-km-z])", src)
              if is_solana(m) and not m.isalpha()})
evm = sorted({m.lower() for src in (text, joined) for m in re.findall(r"0x[0-9a-fA-F]{40}(?![0-9a-fA-F])", src)})
ens = sorted(set(re.findall(r"\b[a-z0-9-]{3,}\.(?:eth|sol)\b", text, re.I)))
links = sorted(set(re.findall(r"(?:https?://)?(?:www\.)?(?:[a-z0-9-]+\.)+(?:com|io|gg|xyz|app|me|ai|link|bio|ee|so|fun|trade)(?:/[^\s\"')]*)?", text, re.I)))
handles = sorted({h for h in re.findall(r"(?<![\w.])@[A-Za-z0-9_.]{3,30}", text) if not h.startswith("@MS4wLj")})
links = [l for l in links if "/@MS4wLj" not in l]

print("SOLANA_ADDRESSES:", *sol or ["-"], sep="\n  ")
print("EVM_ADDRESSES:", *evm or ["-"], sep="\n  ")
print("ENS/SNS_NAMES:", *ens or ["-"], sep="\n  ")
print("LINKS:", *links or ["-"], sep="\n  ")
print("HANDLES:", *handles or ["-"], sep="\n  ")
