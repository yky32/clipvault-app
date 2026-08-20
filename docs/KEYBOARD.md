# ClipVal Keyboard (iOS)

## Goal
Insert **pinned + recent** vault values while typing in other apps — without becoming a keylogger.

## Apple-risk posture (hard)

| Rule | Implementation |
|------|------------------|
| No keystroke logging | Keyboard never observes arbitrary typing; only insert on chip tap |
| No network in extension | No URLSession; no network entitlement |
| Full Access required | iOS requires it for App Group shared with host — **disclose clearly** |
| Full Access purpose | Read on-device `widget_items_json` snapshot only |
| Sensitive items | **Filtered out** of keyboard UI |
| Globe / next keyboard | Always available |
| Secure fields | Host apps may block custom keyboards (expected) |

## User setup
1. Settings → General → Keyboard → Keyboards → Add → **ClipVal**
2. ClipVal → **Allow Full Access** ON
3. Open ClipVal app once (writes App Group snapshot)
4. Switch keyboard while typing

## Data path
Host app `WidgetSnapshotService` → App Group `group.com.clipval` / `widget_items_json`  
→ Keyboard reads same payload (titles for UI; values on tap).

## Bundle
`com.clipval.ClipValKeyboard`

## Review notes
See `store/REVIEW_NOTES_KEYBOARD.txt`
