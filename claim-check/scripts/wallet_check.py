"""On-chain sanity check of a public wallet address (Solana or EVM), using
free public RPC endpoints – no API key.
Usage: python3 -I wallet_check.py <address> [max_signatures=1000]"""
import json, sys, time, urllib.request
from datetime import datetime, timezone

ADDR = sys.argv[1].strip()
MAXSIG = int(sys.argv[2]) if len(sys.argv) > 2 else 1000

def rpc(url, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, body, {"Content-Type": "application/json", "User-Agent": "claim-check/1.0"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.load(r)
            if "error" in d:
                raise RuntimeError(d["error"])
            return d["result"]
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(2 * (attempt + 1)); continue
            raise
    raise RuntimeError("rate limited")

def ts(t):
    return datetime.fromtimestamp(t, timezone.utc).strftime("%Y-%m-%d %H:%M UTC") if t else "?"

if ADDR.lower().startswith("0x"):
    chains = {"Ethereum": "https://ethereum-rpc.publicnode.com",
              "Base": "https://mainnet.base.org",
              "BNB Chain": "https://bsc-rpc.publicnode.com"}
    for name, url in chains.items():
        try:
            bal = int(rpc(url, "eth_getBalance", [ADDR, "latest"]), 16) / 1e18
            n = int(rpc(url, "eth_getTransactionCount", [ADDR, "latest"]), 16)
            code = rpc(url, "eth_getCode", [ADDR, "latest"])
            kind = ("Wallet" if code in ("0x", "0x0") else
                    "Wallet (EIP-7702 delegiert)" if code.startswith("0xef0100") else "Contract")
            print(f"{name}: {kind}, native balance {bal:.4f}, outgoing tx count {n}")
        except Exception as e:
            print(f"{name}: error {e}")
    print("\nPnL/Details ansehen:")
    print(f"  https://debank.com/profile/{ADDR}")
    print(f"  https://etherscan.io/address/{ADDR}")
    print(f"  https://basescan.org/address/{ADDR}")
    sys.exit()

URL = "https://api.mainnet-beta.solana.com"
acct = rpc(URL, "getAccountInfo", [ADDR, {"encoding": "base64"}])
lamports = rpc(URL, "getBalance", [ADDR])["value"]
owner = (acct or {}).get("value", {}) or {}
owner = owner.get("owner", "-")
print(f"SOL balance: {lamports / 1e9:.4f} SOL")
print(f"Account owner program: {owner}"
      + ("  (normale Wallet)" if owner == "11111111111111111111111111111111" else
         "  (kein Account / leer)" if owner == "-" else "  (KEINE normale Wallet – evtl. Token/Programm)"))

sigs, before = [], None
while len(sigs) < MAXSIG:
    opts = {"limit": min(1000, MAXSIG - len(sigs))}
    if before: opts["before"] = before
    page = rpc(URL, "getSignaturesForAddress", [ADDR, opts])
    if not page: break
    sigs += page; before = page[-1]["signature"]
    if len(page) < opts["limit"]: break
    time.sleep(0.3)

if sigs:
    times = [s.get("blockTime") for s in sigs if s.get("blockTime")]
    failed = sum(1 for s in sigs if s.get("err"))
    newest, oldest = max(times), min(times)
    days = max((newest - oldest) / 86400, 1 / 24)
    more = " (Limit erreicht – es gibt ältere)" if len(sigs) >= MAXSIG else ""
    print(f"Transaktionen gezählt: {len(sigs)}{more}, davon fehlgeschlagen: {failed}")
    print(f"Zeitraum: {ts(oldest)}  →  {ts(newest)}  (~{len(sigs)/days:.0f} tx/Tag)")
    if len(sigs) < MAXSIG:
        print(f"Erste Aktivität: {ts(oldest)}  ← Wallet-Alter")
else:
    print("Keine Transaktionen gefunden.")

try:
    tok = rpc(URL, "getTokenAccountsByOwner", [ADDR, {"programId": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"}, {"encoding": "jsonParsed"}])
    held = [a for a in tok.get("value", []) if float(a["account"]["data"]["parsed"]["info"]["tokenAmount"]["uiAmount"] or 0) > 0]
    print(f"Token-Konten: {len(tok.get('value', []))}, davon mit Bestand: {len(held)}")
except Exception as e:
    print(f"Token-Konten: nicht abrufbar ({e})")

print("\nPnL/Trades ansehen (Browser):")
for u in (f"https://gmgn.ai/sol/address/{ADDR}", f"https://solscan.io/account/{ADDR}",
          f"https://birdeye.so/profile/{ADDR}?chain=solana"):
    print("  " + u)
