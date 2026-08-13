# Nearby send — protocol v2

## What
Send **one vault item** to another ClipVal on the **same Wi‑Fi**.
No cloud, no account.

## Trust (v2)
1. **Session PIN** — 6 digits, shown on receiver Settings → Nearby  
2. **AES-CBC + HMAC-SHA256** — value encrypted with key = SHA-256(`clipval-nearby-v2|pin|receiverDeviceId`)  
3. **Human Accept** — nothing saved until receiver taps Save  
4. **Offer queue** — multiple inbound offers wait in order (not dropped)

## Protocol
- Bonjour: `_clipval-nearby._tcp` (TXT `id`, `v=2`)
- `GET /v1/ping` → `{ok, name, deviceId, protocolVersion, pinRequired: true}`
- `POST /v1/offer` JSON:
  - `pin`, `title`, `ciphertext`, `nonce`, `mac`, `fromName`, `fromId`, `isSensitive?`
  - `401` bad pin · `200` accepted · `403` rejected · `408` timeout

## Not included
Files · multi-item · internet relay · background when killed · TLS (LAN + PIN + GCM)
