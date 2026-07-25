# ClipVault

> Store once → Tap once → Paste anywhere.

A private, local-only Flutter vault for storing any value and copying it to the clipboard with a single tap.

See [PRD.md](./PRD.md) for full product requirements.

## One-purpose mandate

ClipVault has exactly **one job**: let the user store any value and copy it with a single tap. No password-manager sprawl, no cloud accounts in MVP.

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
    item_editor/            # create / edit
    settings/               # security, theme, clipboard
    onboarding/             # first-launch
    lock/                   # biometric gate
  l10n/                     # ARB files
```

## Run

```bash
cd ~/Documents/Development/Git/yky/clipvault-app
flutter pub get
flutter run
```

## MVP status (skeleton)

- [x] Create / edit / delete items
- [x] One-tap copy + haptic + toast
- [x] Search by title
- [x] Category filter (free-text category on item)
- [x] Pin to top
- [x] Grid / List view
- [x] AES-256 values at rest
- [x] Biometric app lock
- [x] Theme: System / Light / Dark
- [x] Clipboard auto-clear
- [x] Plain-text export (clipboard)
- [x] Onboarding
- [x] en + zh l10n
- [ ] Encrypted export file
- [ ] iCloud sync (Phase 2)
