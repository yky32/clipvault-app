# ClipVal — Google Play CI (Android Internal Testing ≈ TestFlight)

## Fastlane (same `ios/fastlane` Gemfile / Fastfile)

From repo root (or `ios/` with bundler):

```bash
cd ios && bundle exec fastlane android build_debug
cd ios && bundle exec fastlane android build_release_bundle   # needs signing
cd ios && bundle exec fastlane android upload_internal        # needs Play JSON + signing
```

Lanes live in `ios/fastlane/Fastfile` under `platform :android`.

## Local release signing

```bash
./scripts/create_android_keystore.sh
# writes android/clipval-upload.jks + android/key.properties (gitignored)
flutter build appbundle --release
```

## GitHub Actions

Workflow: **`.github/workflows/deploy-android.yml`**

| Trigger | Job |
|---------|-----|
| `workflow_dispatch` | Always build **debug APK** artifact |
| `workflow_dispatch` + secrets | Build **release AAB**; optional upload Internal Testing |
| `push` main (android paths) | Debug APK CI smoke (no Play upload) |

### Secrets (Play upload)

| Secret | Purpose |
|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | Upload keystore (base64) |
| `ANDROID_KEYSTORE_PASSWORD` | Store password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `clipval`) |
| `ANDROID_KEY_PASSWORD` | Key password |
| `PLAY_STORE_JSON_KEY_BASE64` | Play Console service-account JSON (base64) |
| `PLAY_STORE_JSON_KEY_IS_BASE64` | `true` |

### Play Console (once account verified)

1. Create app **ClipVal** · package `com.clipval`
2. Link Play API service account with **Release to testing** permission
3. Complete Data safety / content rating when publishing
4. Internal testing track → add testers → share link

## Blocked until

- Developer **identity + phone** verification complete (your Console banner)
- App created in Play Console with package `com.clipval`

Until then: use **debug APK** from Actions artifacts / local `flutter build apk --debug`.

## Non-goals (MVP)

- Widget / full Share UX parity
- iCloud equivalent on Android (use `.clipval` file)
- Production track auto-promote
