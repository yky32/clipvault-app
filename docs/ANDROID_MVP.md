# ClipVal Android MVP

**Goal:** Same one job on Android — local vault, one-tap copy, no ClipVal account.  
**Status:** Shell + Fastlane + CI debug APK. Play upload blocked until Console account verified.

## Must (MVP)

- [x] Flutter core vault (shared with iOS)
- [x] `applicationId` `com.clipval`
- [x] Biometric permission + `local_auth`
- [x] Debug APK via Fastlane / GitHub Actions
- [x] Release signing wiring (`key.properties` / CI secrets)
- [x] Fastlane `android upload_internal` (Play Internal Testing)
- [ ] Local keystore created (`./scripts/create_android_keystore.sh`)
- [ ] GitHub secrets for keystore + Play JSON
- [ ] Play Console app created (after identity verify)
- [ ] Device smoke: copy, lock, `.clipval` backup

## Should (soon after MVP)

- [ ] Share intent → open editor (manifest filter stubbed)
- [ ] Nearby permissions tested on Android 12+
- [ ] Adaptive icon brand purple background
- [ ] Data safety form

## Won’t (V1)

- iCloud equivalent
- Home widget
- Production auto-promote

## Commands

```bash
# Debug
flutter build apk --debug
cd ios && bundle exec fastlane android build_debug

# Release AAB (signing required)
./scripts/create_android_keystore.sh
cd ios && bundle exec fastlane android build_release_bundle
cd ios && bundle exec fastlane android upload_internal
```

CI: Actions → **Deploy Android** · docs: `docs/CI_PLAY.md`
