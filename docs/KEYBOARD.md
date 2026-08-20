# ClipVal Keyboard (iOS)

## Goal
**Surpass CopyNow-class UX**: search + pinned/recent chips → one-tap insert in any field — with ClipVal privacy (no keylogging, sensitive hidden, no network).

## Apple-risk posture
| Rule | Implementation |
|------|----------------|
| No keylogging | Only insert on chip tap |
| No network | No URLSession |
| Full Access | Required for App Group — disclosed in Settings |
| Sensitive | Filtered out of keyboard UI |
| Globe | Always present |

## App Groups (required for insert)
Bundle: `com.clipval.ClipValKeyboard`  
Group: `group.com.clipval`  
Keys: `keyboard_items_json` (preferred), fallback `widget_items_json`

### One-time Portal link
If CI archive fails on App Groups:
1. [developer.apple.com](https://developer.apple.com) → Identifiers → `com.clipval.ClipValKeyboard`
2. Enable **App Groups** → `group.com.clipval`
3. Or locally: `cd ios && bundle exec fastlane ios associate_keyboard_app_group`  
   (needs `FASTLANE_USER` + app-specific password)

Then Deploy again (force profile refresh).

## User setup
1. Settings → General → Keyboard → Add **ClipVal**
2. ClipVal → **Allow Full Access**
3. Open ClipVal once (writes snapshot)
4. Switch keyboard → search / tap chip → insert

## Review
`store/REVIEW_NOTES_KEYBOARD.txt`
