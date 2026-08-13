# Nearby send (LocalSend-inspired MVP)

## What
Send **one vault item** to another ClipVal on the **same Wi‑Fi**.
No cloud, no account. Receiver must **Accept** before save.

## Protocol v1
- Bonjour: `_clipval-nearby._tcp`
- `GET /v1/ping` → `{ok, name, deviceId, protocolVersion}`
- `POST /v1/offer` JSON `{title, value, fromName, fromId, isSensitive?, categoryName?}`
  - Holds until Accept/Reject (~55s)
  - `200` accepted · `403` rejected · `408` timeout

## UX
- Settings → Nearby (default **off**)
- Long-press item → **Send nearby** (only if enabled)
- Receiver dialog → Save to vault / Decline

## Trust
LAN + human Accept (AirDrop-like). Values do not leave the local network via ClipVal servers.

## Not in MVP
- File transfer · multi-item · PIN · internet relay · background receive when killed
