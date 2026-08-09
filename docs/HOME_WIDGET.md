# ClipVal Home Screen Widget

## What it does

Shows up to **4** vault items (pinned first, then recently copied) on the iOS Home Screen.

| iOS | Tap behavior |
|-----|----------------|
| **17+** | **Copies on the Home Screen** via App Intent — app does **not** open. System may show a small “Copied …” dialog. |
| **15–16** | Opens ClipVal via `clipval://copy?id=…` (fallback). |

Rebuild / reinstall after changing the widget so the Home Screen picks up the new binary.

## Architecture

| Layer | Role |
|--------|------|
| `WidgetSnapshotService` | After vault changes, writes JSON of top items into App Group `group.com.clipval` |
| `home_widget` | Flutter bridge for App Group + `WidgetCenter.reloadTimelines` |
| `ClipValWidget` extension | WidgetKit UI; reads the same JSON key `widget_items_json` |

**Security note:** Widget rows include **plaintext values** in the App Group so the UI can deep-link copy without re-decrypting Hive in the extension. Only the top 4 items are snapshotted — not the full vault.

## First-time setup (Apple Developer)

1. Register App Group **`group.com.clipval`** on team `3G34999H3A`.
2. Enable App Groups on App IDs:
   - `com.clipval`
   - `com.clipval.ClipValWidget`
3. Regenerate App Store / development provisioning profiles (CI `sigh` will pick up groups once App IDs are updated).

## Local test

1. `flutter run` on a device/simulator and add a few vault items (pin some).
2. Long-press Home Screen → **Add Widget** → **ClipVal**.
3. Tap a row → app opens (or returns) and copies.

## Files

- `lib/core/services/widget_snapshot_service.dart`
- `ios/ClipValWidget/*`
- `ios/Runner/Runner.entitlements` (App Group)
- Embed via Runner build phase **Embed ClipVal Widget** (script; avoids Xcode “cycle” with Flutter Thin Binary)
