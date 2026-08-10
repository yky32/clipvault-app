# ClipVal — prepare 1.0.4 vs 1.1 (after 1.0.3 ships)

**Do not submit until 1.0.3 is Approved / Ready for Sale.**  
Then pick **one** path and ship.

---

## What’s live / in flight (today)

| Version | Status | Rough content |
|---------|--------|----------------|
| **1.0.2** | Live | Core vault |
| **1.0.3** | Waiting for Review | Secure `.clipval` backup, import preview, bulk delete, widget polish, editor/grid fixes (binary under review ≠ latest TF) |
| **TF 1.0.3 (52)** | TestFlight | Main: Phase **C + D + E** (widget speed, trust surface, **iCloud**) |

App Store **1.0.3 under review** may be an **older build** than TF 52. After 1.0.3 is live, the next App Store binary should be cut from **current `main`**.

---

## Option A — **1.0.4** (patch / quiet follow-up)

**When to choose:** You want a fast, low-drama update after 1.0.3; save “big story” for later.

### Scope (recommended)

| Include | Phase | Why |
|---------|--------|-----|
| Widget favorites, hide titles, large size, responsive grid | C | One-tap from Home Screen |
| Sort vault, duplicate, denser recent + hold-to-pin | C | Vault speed |
| Face ID to reveal, auto-lock timeout, sensitive flag, undo delete | D | Trust without marketing splash |
| Share → Save to ClipVal (if not already in 1.0.3 binary) | B | Capture |
| **Optional:** iCloud toggle | E | Only if you’re OK with privacy review questions on a patch |

**Default recommendation for 1.0.4:** **C + D (+ Share if missing). Defer iCloud to 1.1.**

### Marketing version

- `pubspec.yaml`: `1.0.4+<build>` (Fastlane will bump build)
- ASC: new version **1.0.4** (after 1.0.3 is closed / for sale)

### App Review notes (short)

- No account; all data on device unless user exports `.clipval` or (if included) turns on iCloud.
- Demo: create item → copy; Settings app lock; widget if applicable.
- If iCloud **not** in 1.0.4: say “No cloud sync in this build.”

### ASC checklist — 1.0.4

- [ ] 1.0.3 **Ready for Sale**
- [ ] Create version **1.0.4** in App Store Connect
- [ ] Upload build from `main` (TF first, then select for 1.0.4)
- [ ] What’s New: `store/whats_new_1.0.4_en-US.txt` + `zh-Hant`
- [ ] Screenshots: reuse 1.0.3 unless UI changed a lot
- [ ] Privacy Nutrition: no new data collection if iCloud **off** the binary
- [ ] Submit → After Approval (or Manual)

---

## Option B — **1.1** (minor / story release)

**When to choose:** You want a clear **multi-device / trust** moment on the store page.

### Scope (recommended)

Everything in **1.0.4 scope** **plus**:

| Include | Phase | Headline |
|---------|--------|----------|
| **Sync with iCloud** (opt-in, CloudKit private) | E | “Your iCloud, never ours” |
| Deploy CloudKit schema **Development → Production** | E | Required for App Store / production iCloud |
| Privacy copy in Settings | E | Already in app |

### Marketing version

- `pubspec.yaml`: `1.1.0+<build>` (or `1.1.0` marketing)
- ASC: new version **1.1**

### App Review notes (iCloud)

- Sync is **opt-in**, **off by default**.
- Uses **user’s private CloudKit** only; ClipVal has **no** account server.
- Values are **encrypted on device** before upload; ClipVal never receives plaintext.
- Reviewer: enable iCloud on device → Settings → Sync with iCloud → Sync now.
- Still supports `.clipval` password backup without iCloud.

### ASC checklist — 1.1

- [ ] 1.0.3 (and any 1.0.4 if you did patch first) **Ready for Sale**
- [ ] CloudKit Dashboard: **Deploy Schema Changes** to **Production** for `iCloud.com.clipval`
- [ ] Create version **1.1** in App Store Connect
- [ ] Upload build from `main` with iCloud entitlements
- [ ] What’s New: `store/whats_new_1.1_en-US.txt` + `zh-Hant`
- [ ] App Privacy: declare **if** iCloud/CloudKit data use requires labels (encrypted vault payload to iCloud, user-initiated)
- [ ] Review notes (above)
- [ ] Optional: one more screenshot for Settings → iCloud
- [ ] Submit

---

## Side-by-side

| | **1.0.4** | **1.1** |
|--|-----------|---------|
| **Story** | Faster vault + safer reveal | Multi-device private sync |
| **iCloud** | Prefer **omit** | **Include** + Production schema |
| **Review risk** | Lower | Medium (privacy / iCloud questions) |
| **User-facing delta vs 1.0.3** | Widget + trust polish | That **+** Sync with iCloud |
| **Version code** | `1.0.4+N` | `1.1.0+N` |

---

## Suggested decision after 1.0.3 ships

```
If you want one calm update soon     → ship 1.0.4 (C+D, no iCloud)
     then later 1.1 with iCloud

If you want one store moment         → skip 1.0.4, ship 1.1 (C+D+E)
```

**Do not** open both 1.0.4 and 1.1 in ASC at once for the same platform train without a clear plan—pick one next version after 1.0.3.

---

## Engineering prep (no version bump until you choose)

Already on `main` / TF 52:

- Phase C, D, E code  
- Entitlements: `iCloud.com.clipval`  
- Docs: `docs/ICLOUD_SYNC.md`

When you select a path:

```bash
# 1.0.4
# edit pubspec: version: 1.0.4+53   (or let Fastlane bump build only after marketing bump)
# ASC What’s New from store/whats_new_1.0.4_*

# 1.1
# edit pubspec: version: 1.1.0+53
# CloudKit Production deploy
# ASC What’s New from store/whats_new_1.1_*
# gh workflow run Deploy  OR  fastlane ios upload_testflight
```

---

## Files in this prep pack

| File | Use |
|------|-----|
| `store/whats_new_1.0.4_en-US.txt` | ASC 1.0.4 EN |
| `store/whats_new_1.0.4_zh-Hant.txt` | ASC 1.0.4 繁中 |
| `store/whats_new_1.1_en-US.txt` | ASC 1.1 EN |
| `store/whats_new_1.1_zh-Hant.txt` | ASC 1.1 繁中 |
| `store/RELEASE_PLAN_1.0.4_vs_1.1.md` | This decision doc |

---

*Prepared while 1.0.3 is Waiting for Review. Revisit after Ready for Sale.*
