# Share → Save to ClipVal (Phase B)

Local-only capture path: other apps → system Share Sheet → ClipVal.

## Flow

1. User selects text/URL in any app → **Share** → **ClipVal**
2. `ClipValShare` extension writes to App Group `group.com.clipval`:
   - `pending_share_value` (required)
   - `pending_share_title` (optional)
3. Extension opens `clipval://share`
4. Host app drains payload via method channel `com.clipval/share` → `takePendingShare`
5. Vault opens **Add item** prefilled (title derived from first line if needed)

No network. No ClipVal servers.

## Targets

| Target | Bundle ID |
|--------|-----------|
| Runner | `com.clipval` |
| Share | `com.clipval.ClipValShare` |

## Test (device or simulator)

1. Full install (not just hot reload) so the extension is embedded.
2. Open **Notes** (or Safari) → select text → Share → ClipVal.
3. ClipVal should open the editor with value filled → edit title → slide to save.

## CI

Fastlane fetches `SIGH_NAME_SHARE` for `com.clipval.ClipValShare` (App Store profile) and signs like the widget extension.
