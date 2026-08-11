# CTO Ticket — ClipVal iCloud sync fail (Production schema)

**ID:** CLIPVAL-CK-001  
**Status:** Open · **blocked on CEO CloudKit Dashboard deploy** · eng UX shipped in branch  
**Desk:** CTO  
**Product:** clipval.app (TestFlight)  
**Severity:** High for iCloud feature; local vault OK  
**Created:** 2026-08-11  
**From:** COO handoff (Wayne screenshot)

---

## Symptom
Settings → iCloud 同步 →「立即同步」→ dialog:

```
無法同步
Error saving record <CKRecordID: …; recordName=cat_sys_developer,
zone ID=ClipValVault:__defaultOwner__> to server:
Cannot create new type Category in production schema
```

## Root cause
TestFlight uses **CloudKit Production**. App saves `Category` (`cat_sys_developer`) but **Production schema has no `Category` record type**.

CloudKit forbids creating new types at runtime in Production. Must **Deploy Schema Development → Production**.

## Code / docs refs
| Item | Path |
|------|------|
| Record types | `ios/Runner/CloudKitSyncChannel.swift` — `ClipItem`, `Category`, `VaultMeta` |
| Container | `iCloud.com.clipval` |
| Zone | `ClipValVault` |
| Dev flow | `docs/ICLOUD_SYNC.md` |
| Release gate already listed | `store/RELEASE_PLAN_1.0.4_vs_1.1.md` — Deploy schema before TF/AS |

## Fix (ops — CEO or whoever has CloudKit Dashboard)
1. [CloudKit Dashboard](https://icloud.developer.apple.com/) → container `iCloud.com.clipval`
2. Development schema: confirm `ClipItem`, `Category`, `VaultMeta` (+ zone `ClipValVault`)
3. If missing in Dev: run **Xcode Debug** build, enable sync once (auto-create types)
4. **Deploy Schema Changes → Production**
5. Kill TestFlight app → 立即同步 again

## Workaround
- Disable iCloud sync; use encrypted backup export
- Local vault remains usable

## CTO engineering follow-ups (optional, after deploy)
- [x] Hard gate doc: `docs/CLOUDKIT_DEPLOY_CHECKLIST.md` + CI note
- [x] Friendlier error (`schema_production` → 繁中/EN，唔 dump CKRecordID)
- [x] Add `docs/CLOUDKIT_DEPLOY_CHECKLIST.md` one-pager
- [ ] Verify all Category/ClipItem/VaultMeta fields match prod after **CEO deploy**

## Out of scope for this ticket
- Android CloudKit (N/A — private CK is iOS)
- Redesign sync protocol

## Done when
- TestFlight「立即同步」succeeds with system categories (incl. developer)
- Production schema shows `Category` type
