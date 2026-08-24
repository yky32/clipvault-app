# ClipVal Home Screen Widget

> Related: system **Share → ClipVal** uses the same App Group (`group.com.clipval`)
> with keys `pending_share_value` / `pending_share_title` (see `ClipValShare`).

---

## 🔒 LOCKED — functional copy path (do not “simplify” without device QA)

**Status:** Proven working on Wayne’s device — **1.1.1 build 116** (PR #74 path).  
**Tag:** `widget-copy-locked-v1` (main @ functional multi-write deep link).

### What works (product truth)

| Step | Behavior |
|------|----------|
| 1 | Tap widget tile |
| 2 | Opens ClipVal via `clipval://copy?id=<uuid>` |
| 3 | **AppDelegate** writes `UIPasteboard.general.string` from App Group (0 / 0.15 / 0.5 / 1.1s) |
| 4 | Flutter `WidgetDeepLink` reinforces + HUD `title · N chars` |
| 5 | Auto bounce Home (~1s) via `moveToBackground` |
| 6 | User opens WhatsApp → long-press → **貼上 has real text** |

### Why this path (failed experiments)

| Approach | Result on device |
|----------|------------------|
| AppIntent `openAppWhenRun=false` + `UIPasteboard` in **widget extension** | Copied UI / sometimes Paste menu, **WhatsApp insert empty** |
| AppIntent + `setItems` / multi-type | Empty paste / wiped clipboard |
| Empty `value` intent param | `string = ""` clears pasteboard while still saying Copied |
| Bounce **before** multi-write | Completely cannot paste |
| Pure “no open app” | **Not reliable** for WhatsApp on current iOS |

**Conclusion:** System clipboard that WhatsApp will actually insert must be written from the **host app process**. Zero-jump + guaranteed paste is **not stable** on this device/OS.

### DO NOT change without re-QA on real iPhone + WhatsApp

1. Widget cell **must** stay `Link(clipval://copy?id:)` (not AppIntent-only default).
2. **Do not** clear pasteboard with `pb.string = nil` before write.
3. **Do not** use `setItems` as primary write (empty insert).
4. **Do not** bounce Home before ~1s multi-write completes.
5. App Group must keep **plaintext** `wv_<id>` + `widget_items_json` + `widget_values_map`.
6. User must open ClipVal once after install so snapshot is populated.

### Key files (locked path)

| File | Role |
|------|------|
| `ios/ClipValWidget/ClipValWidget.swift` | Tile → `Link(clipval://copy?id=)` only |
| `ios/Runner/AppDelegate.swift` | `handleClipValCopyURL`, `writeSystemPasteboard`, delayed bounce |
| `lib/core/services/widget_deep_link.dart` | Flutter reinforce + HUD + bounce request |
| `lib/core/services/widget_snapshot_service.dart` | Snapshot JSON + values into App Group |

---

## UX follow-ups (research only — do not ship untested)

Goal: keep **paste correctness**, reduce jump flash.

| Idea | Notes | Risk |
|------|--------|------|
| A. Shorter bounce (0.5s) | Faster return Home | May paste empty again if too fast |
| B. openAppWhenRun + silent bounce | No URL round-trip | Intent empty-value regressions |
| C. ClipVal Keyboard insert path | Widget only “selects”; keyboard inserts | Different mental model |
| D. Minimal full-screen “Copied” route | No vault UI flash | Still opens app process |
| E. Stay in previous app via better suspend | Timing / App Review | Private-ish suspend API |
| F. Accept flash; polish HUD only | Lowest risk | UX still “weird” |

**Rule:** Any UX experiment needs side-by-side QA: widget → WhatsApp 貼上 **non-empty**. If empty → revert to locked path.

---

## Architecture (snapshot)

| Layer | Role |
|--------|------|
| `WidgetSnapshotService` | Top N items JSON + per-id values → App Group |
| `home_widget` + native `writeSnapshot` | Authoritative App Group write + reload |
| `ClipValWidget` | UI + deep link only |
| Host `AppDelegate` | Real pasteboard + bounce |

**Security:** Widget snapshot includes **plaintext values** for top N only (not full vault).

## First-time setup (Apple Developer)

1. App Group **`group.com.clipval`**
2. Enable on `com.clipval` + `com.clipval.ClipValWidget`
3. Regenerate profiles

## Local test checklist

1. `flutter run` / TF install → open app once → vault has items.
2. Add widget → tap tile → HUD shows **N chars > 0**.
3. Auto or manual Home → WhatsApp → long-press → paste **non-empty**.
4. Rebuild widget after binary change (remove/re-add widget if stale).
