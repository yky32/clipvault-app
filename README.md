# clipVAuLt

> Store once → Tap once → Paste anywhere.

A private, local-only Flutter vault for storing any value and copying it to the clipboard with a single tap.

See [PRD.md](./PRD.md) for full product requirements.

## One-purpose mandate

clipVAuLt has exactly **one job**: let the user store any value and copy it with a single tap. No password-manager sprawl, no cloud accounts in MVP.

## Stack (aligned with Triftly / Depozio)

| Layer | Choice |
|--------|--------|
| Framework | Flutter (iOS + Android) |
| State | `flutter_bloc` + `equatable` |
| Routing | `go_router` |
| Local DB | `hive_ce` |
| Encryption | AES-256 (`encrypt`) + key in `flutter_secure_storage` |
| Biometrics | `local_auth` |
| Fonts | Satoshi (same family as Triftly / Depozio) |
| L10n | English + Traditional Chinese (`zh`) |

## Project layout

```
lib/
  main.dart                 # bootstrap
  app.dart                  # MaterialApp.router
  core/
    bootstrap/              # AppBootstrap services
    theme/                  # colors, theme, ThemeController
    navigation/             # go_router
    models/                 # ClipItem, Category
    services/               # encryption, repos, auth, clipboard, settings
  features/
    vault/                  # home list/grid + one-tap copy
    item_editor/            # create / edit via bottom sheet (Triftly pattern)
    settings/               # security, theme, clipboard
    onboarding/             # first-launch
    lock/                   # biometric gate
  l10n/                     # ARB files
```

## Input pattern

User input (add / edit item) opens a **modal bottom sheet** — same approach as Triftly (`TriftlyBottomSheet` + `SheetScaffold`):

```dart
ItemEditorBottomSheet.show(context);           // create
ItemEditorBottomSheet.show(context, itemId: id); // edit
```


## Run

```bash
cd ~/Documents/Development/Git/yky/clipvault-app
flutter pub get
flutter run
```

## TestFlight (Fastlane — same pattern as Depozio / Triftly)

```bash
cd ios
bundle install
bundle exec fastlane ios upload_testflight
# or interactive:
./fastlane/fastlane_menu.sh
```

Details: [ios/fastlane/README.md](./ios/fastlane/README.md)

## Security notes (MVP)

- **Values** encrypted at rest (AES-256); key in Keychain / secure storage
- **Titles / metadata** are not encrypted
- App lock is **opt-in**; when enabled, vault re-locks after background
- Plain-text export requires confirm (+ biometrics if lock is on)

## MVP status

- [x] Create / edit / delete items
- [x] One-tap copy + haptic + toast
- [x] Search by title
- [x] Category filter
- [x] Pin to top
- [x] Grid / List view + last used
- [x] AES-256 values at rest
- [x] Biometric app lock + re-lock on resume
- [x] Theme: System / Light / Dark
- [x] Clipboard auto-clear
- [x] Plain-text export (confirm + re-auth)
- [x] Onboarding
- [x] en + zh l10n
- [x] Fastlane → TestFlight
- [ ] Encrypted export file
- [ ] iCloud sync (Phase 2)
