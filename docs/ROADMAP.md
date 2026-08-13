# ClipVal product phases

**Core values (hard rules)**  
1. **No account** — no ClipVal login, no identity server  
2. **All local** — vault lives on device; user owns the bits  
3. **Won’t leak** — we never see values; anything that leaves the device is **user-initiated** and preferably **password-locked**

**One job:** store a value → one tap → copy → paste anywhere.

---

## Status snapshot (≈ 1.0.3)

| Area | State |
|------|--------|
| Vault CRUD, search, categories, pin, grid/list | Done |
| One-tap copy + HUD + clipboard auto-clear | Done |
| App lock (biometrics) + AES values at rest | Done |
| Themes / palettes, en + zh | Done |
| Home Screen widget (4×2, App Intent / deep link) | Done |
| Bulk delete (multi-select) | Done |
| CSV import + dry-run preview | Done |
| Secure backup (`.clipval`, password + AES-GCM) | Done |
| Plain CSV export | Removed (leak surface) |
| iCloud sync | Done in tree (opt-in CloudKit private) |

---

## Phase A — MVP complete (shipped)

**Goal:** Trustworthy local vault, App Store–ready core loop.

- Local-only storage, encrypted values  
- Create / edit / copy / delete / search / filter  
- App lock, clipboard clear, onboarding, l10n  
- Fastlane → TestFlight  

**Exit:** Users can live on ClipVal daily without cloud.

---

## Phase B — Capture & migrate (mostly shipped)

**Goal:** Get values *in* and *off* the device without accounts.

| Item | Status |
|------|--------|
| Import CSV + preview (new · skipped) | Done |
| Export secure backup (`.clipval`) | Done |
| Import `.clipval` + password | Done |
| Bulk delete for cleanup after import | Done |
| Share sheet → **Save to ClipVal** | Done (iOS Share Extension → App Group → editor) |
| Long value / template editor polish | Done (iterate if needed) |

**Exit:** Phone swap works with one encrypted file + password; sharing *into* the app is one step.

---

## Phase C — Faster one-tap (shipped in tree)

**Goal:** Copy without digging; never leave the one-purpose box.

| Item | Status |
|------|--------|
| Widget favorites only (pinned) | Done — Settings toggle |
| Hide widget titles when app lock on | Done — monogram + ··· |
| Widget medium + large families | Done — medium 8 · large 16 |
| Recently copied strip | Done — denser; hold to pin |
| Duplicate item | Done — action sheet |
| Sort vault | Done — updated / last used / A–Z |
| Spotlight (title only) | Done — tap → copy |

**Exit:** Top 8 values reachable in &lt;1s from Home Screen or search.

---

## Phase D — Trust surface (before heavy sync)

**Goal:** Feel safer than Notes without becoming a password manager.

| Item | Status |
|------|--------|
| Require Face ID to **reveal** value in editor | Done — Settings (when app lock on; default on) |
| Hide titles on widget when locked / sensitive | Done — monogram; sensitive always masks |
| Auto-lock timeout options | Done — immediate · 1m · 5m · 15m |
| Undo delete (few seconds) | Done — snackbar Undo · 5s |
| Optional “sensitive” flag | Done — mask title in vault/recent/widget |

**Exit:** Power users trust ClipVal for codes/API keys, not just grocery codes.

---

## Phase E — Optional iCloud (PRD Phase 2) — shipped in tree

**Goal:** Multi-device without ClipVal servers.

| Item | Status |
|------|--------|
| Toggle: **Sync with iCloud** | Done — Settings (iOS only, default off) |
| CloudKit **private** database | Done — container `iCloud.com.clipval` |
| Client-side AES before upload | Done — ciphertext + VaultMeta master key |
| Privacy copy | Done — EN/ZH |
| Conflict rule | Done — **last-write-wins** by `updatedAt` |
| Tombstones for deletes | Done |
| `.clipval` backup still available | Done |

See `docs/ICLOUD_SYNC.md` for Apple portal / schema setup.

**Exit:** Two iPhones stay in sync; no account screen in ClipVal.

**Non-goals:** ClipVal backend, email login, team vaults.

---

## Phase F — Android (PRD Phase 3–ish)

**Goal:** Same one job on Android, still local-first.

- Flutter shell already exists; harden vault + biometrics  
- Encrypted backup (same `.clipval` format) for cross-platform file transfer  
- Optional later: encrypted file sync via user-chosen storage (not ClipVal cloud)  
- Home widget when iOS path is stable  

**Exit:** Android users get core loop + secure backup; no forced Google account for the vault itself.

---

## Suggested near-term sequence

```
Now ──► Phase E: iCloud private sync (done in tree — enable CloudKit container)
     ──► App Store marketing if needed
     ──► Phase F: Android parity
```

### Explicitly out of roadmap

- ClipVal accounts / social / teams  
- Full password manager / autofill suite  
- Notes / folders / rich documents  
- Analytics of vault contents  
- Unencrypted “export everything” by default  

---

## How to pick the next sprint

| If the pain is… | Build… |
|-----------------|--------|
| “I keep pasting from Messages/Notes” | **Share → Save to ClipVal** (Phase B) |
| “I want copy without opening the app” | **Widget favorites** (Phase C) |
| “I’m nervous opening values” | **Face ID to reveal** (Phase D) |
| “New phone every year” | Already: **`.clipval`**; next: **iCloud** (Phase E) |

---

*Living doc — update when a phase ships. Product rules above override feature enthusiasm.*
