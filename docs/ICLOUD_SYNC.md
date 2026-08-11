# Phase E — iCloud sync (CloudKit private)

## Product rules

- **Opt-in only** (Settings → iCloud → Sync with iCloud). Default off.
- **Private CloudKit database** only (`iCloud.com.clipval`).
- **Client-side AES** still wraps every value; CloudKit stores ciphertext + metadata.
- Master key is stored in CloudKit `VaultMeta.masterKey` so a second device can decrypt — still only inside the user’s private iCloud.
- **Conflict rule:** last-write-wins by `updatedAt` (tombstones use `deletedAt`).
- **`.clipval` backups remain** for off-Apple / disaster recovery.

Copy for UI: *“Goes to your iCloud, never to us.”*

## One-time Apple setup

1. [Apple Developer](https://developer.apple.com/account) → Identifiers → App ID `com.clipval`
   - Enable **iCloud** with **CloudKit**
   - Create container **`iCloud.com.clipval`** (or link an existing one)
2. Same container on any App Store / development profiles used for Runner
3. Xcode → Runner → Signing & Capabilities → confirm **iCloud (CloudKit)** + container
4. First run in **Development** schema: CloudKit creates record types on first save:
   - `ClipItem`, `Category`, `VaultMeta`
5. Promote schema to **Production** in CloudKit Dashboard before App Store / TestFlight iCloud
   - **Checklist:** [`CLOUDKIT_DEPLOY_CHECKLIST.md`](./CLOUDKIT_DEPLOY_CHECKLIST.md) (CLIPVAL-CK-001)

Entitlements live in `ios/Runner/Runner.entitlements`.

## Runtime flow

1. User turns sync on → account status check → ensure custom zone `ClipValVault` →
   zone-change fetch (no CKQuery) → reconcile master key → merge LWW → push local.
2. First device seeds schema by **pushing** records into the zone (Development auto-creates types).
3. Vault create/update/delete → debounced push (~1.2s).
4. Deletes also write CloudKit tombstones (`deletedAt`).
5. App resume + cold start → schedule sync if enabled.

**Why a custom zone?** CKQuery needs queryable indexes (`recordName`, etc.). Fresh Development
schemas do not have them, which caused `Did not find record type` / `not marked queryable`.
Zone fetch does not require those indexes.

## Files

| Layer | Path |
|-------|------|
| Native bridge | `ios/Runner/CloudKitSyncChannel.swift` |
| Dart engine | `lib/core/services/icloud_sync_service.dart` |
| LWW helpers | `lib/core/services/icloud_sync_merge.dart` |
| Settings | Security/data section in Settings page |

## Non-goals (this phase)

- ClipVal backend, email login, shared/family vaults
- Android CloudKit (Phase F uses file backup / later user-chosen storage)
- Real-time multiplayer editing (sync is pull/push, not CRDT)
