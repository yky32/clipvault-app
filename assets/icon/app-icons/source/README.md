# App icon source

- `app-icon-1024.png` — **master** full-bleed brand purple (no white canvas corners).
- Used by `flutter_launcher_icons` (see root `pubspec.yaml`).

## Rules
- Corners must be brand purple `#4E57AA` (78,87,170), **not white**.
- iOS masks to squircle; white corners still show as fringe on some surfaces / previews.
- Regenerate: `dart run flutter_launcher_icons`

## History
- Older master had white corners; replaced from `clipval-www/public/app-icon.png` + outer-ring clean (2026-08).
