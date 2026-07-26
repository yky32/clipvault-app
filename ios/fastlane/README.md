# ClipVal — Fastlane (TestFlight)

Automated iOS build + TestFlight upload, aligned with **Depozio** / **Triftly**.

## One-command TestFlight

From the repo root (or `ios/`):

```bash
cd ios
bundle install
bundle exec fastlane ios upload_testflight
```

Or use the interactive menu (same as Depozio):

```bash
cd ios/fastlane
./fastlane_menu.sh
# pick [5] ios upload_testflight
```

### What `upload_testflight` does

1. Bumps `pubspec.yaml` build number (`1.0.0+N` → `+N+1`)
2. Commits + pushes that bump
3. `flutter pub get` + `pod install`
4. `flutter build ios --release` + archive IPA (App Store export)
5. Uploads IPA to TestFlight with release notes from last git commits
6. On missing App Store Connect app → tries `create_app` then retries
7. On signing failure → tries `setup_appstore_signing` then retries once

## First-time setup

### 1. Apple Developer

- Team ID in Xcode / Fastfile: **`3G34999H3A`**
- Bundle ID: **`com.yky.clipval`**
- Display name: **ClipVal**

Ensure the App ID exists (or run `create_app`):

```bash
cd ios && bundle exec fastlane ios create_app
```

### 2. Signing (Automatic)

Open Xcode once:

```bash
open ios/Runner.xcworkspace
```

Runner → **Signing & Capabilities** → Automatic → team **3G34999H3A**.

Or CLI:

```bash
cd ios && bundle exec fastlane ios setup_appstore_signing
```

### 3. Auth for upload

**Option A — Apple ID (local, interactive 2FA)**  
Uses `FASTLANE_USER` (default `wayneyu.dev@gmail.com`). First run may prompt for password / 2FA.

**Option B — App Store Connect API key (recommended, non-interactive)**  

Create a key in App Store Connect → Users and Access → Keys, then either:

- Save the `.p8` as `~/.appstoreconnect/api_key.p8`, and set:

```bash
export APP_STORE_CONNECT_API_KEY_ID=XXXXXXXX
export APP_STORE_CONNECT_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export APP_STORE_CONNECT_API_KEY_CONTENT="$(cat ~/.appstoreconnect/api_key.p8)"
```

- Or put the same vars in `ios/fastlane/.env` (gitignored).

Copy defaults:

```bash
cp ios/fastlane/.env.default ios/fastlane/.env
# edit .env
```

### 4. Gems + pods (Ruby 2.6 via rbenv — same as Triftly)

System `/usr/bin/ruby` can fail on modern `ffi`. Use the project helper:

```bash
# once: brew install rbenv ruby-build && rbenv install 2.6.10
./ios/install_gems_and_pods.sh
```

That installs Gemfile gems under rbenv 2.6.10 and runs `pod install`.

## Other lanes

| Lane | Purpose |
|------|---------|
| `ios build_debug` | Debug build, no codesign |
| `ios build_release` | Release, no codesign |
| `ios build_ipa` | IPA (development by default) |
| `ios build_ipa export_method:app-store` | App Store IPA only |
| `ios upload_testflight skip_build:true` | Re-upload existing IPA |
| `ios create_app` | Register ASC + Developer portal |
| `ios setup_appstore_signing` | Dist cert + profile |
| `android build_release_apk` | Android APK (debug signing until Play keystore) |
| `test` | `flutter test` |

## Env overrides

| Variable | Default |
|----------|---------|
| `FASTLANE_USER` | `wayneyu.dev@gmail.com` |
| `FASTLANE_TEAM_ID` | `3G34999H3A` |
| `FASTLANE_ITC_TEAM_ID` | (optional, multi-team ASC) |
| `APP_STORE_CONNECT_API_KEY_*` | (optional API key auth) |

## Notes

- ClipVal has **no** Flutter `--dart-define` secrets (unlike Triftly). Local-only vault.
- Android release still uses debug signing in Gradle until you add a Play keystore.
- After first TestFlight upload, complete App Store Connect listing (privacy, screenshots) before public release — not required for internal TestFlight.
