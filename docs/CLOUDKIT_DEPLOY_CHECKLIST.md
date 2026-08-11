# CloudKit Production deploy checklist (CLIPVAL-CK-001)

**Container:** `iCloud.com.clipval`  
**Custom zone:** `ClipValVault`  
**Record types (required):** `ClipItem` · `Category` · `VaultMeta`  

TestFlight / App Store builds use the **Production** environment. CloudKit **does not** allow creating new record types at runtime in Production.

---

## When you need this

| Symptom | Meaning |
|---------|---------|
| `Cannot create new type Category in production schema` | Prod missing `Category` (or other type) |
| `Cannot create new type ClipItem…` | Same for that type |
| Local vault works; only「立即同步」fails | Schema / iCloud only |

**Workaround until deployed:** turn iCloud sync off; use password-locked `.clipval` backup.

---

## Deploy Dev → Production (CEO / Apple account)

1. Open [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select team → container **`iCloud.com.clipval`**
3. **Schema** → **Development**
   - Confirm record types: **ClipItem**, **Category**, **VaultMeta**
   - Confirm custom zone usage is OK (app creates zone `ClipValVault` at runtime)
4. If Development is missing types:
   - Run **Debug** build from Xcode (`flutter run` / scheme Debug)
   - Settings → enable iCloud sync once (Development auto-creates types on first save)
   - Refresh Dashboard Development schema
5. Click **Deploy Schema Changes…** (or **Deploy to Production…**)
6. Review diff → deploy **all** missing types/fields to **Production**
7. Production schema must list the three record types

### After deploy

1. Force-quit TestFlight ClipVal  
2. Settings → iCloud → **立即同步**  
3. Expect success HUD（已同步）  
4. Optional: second device with same Apple ID pulls categories/items  

---

## Release gate (before shipping iCloud in a build)

- [ ] Development schema has ClipItem / Category / VaultMeta  
- [ ] **Production** schema matches (Deploy done)  
- [ ] TestFlight「立即同步」OK with at least one system category (e.g. developer)  
- [ ] Listed in `store/RELEASE_PLAN_1.0.4_vs_1.1.md` for 1.1 / iCloud story  

CI **cannot** deploy CloudKit schema — human + Dashboard only.

---

## Engineering refs

| Piece | Path |
|-------|------|
| Native bridge | `ios/Runner/CloudKitSyncChannel.swift` |
| Dart engine | `lib/core/services/icloud_sync_service.dart` |
| Product rules | `docs/ICLOUD_SYNC.md` |
| Ticket | `docs/CTO_TICKET_CLIPVAL_CK_001.md` |

Friendly UX: production schema errors map to `schema_production` → localized copy (no raw `CKRecordID` dump).
