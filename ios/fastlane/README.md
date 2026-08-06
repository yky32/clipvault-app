fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### get_dependencies

```sh
[bundle exec] fastlane get_dependencies
```

Get Flutter dependencies

### test

```sh
[bundle exec] fastlane test
```

Run Flutter tests

### clean_all

```sh
[bundle exec] fastlane clean_all
```

Clean all build artifacts

----


## iOS

### ios build_debug

```sh
[bundle exec] fastlane ios build_debug
```

Build iOS app for development (Debug)

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build iOS app for release (no codesign)

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build iOS app and create IPA (requires code signing)

Options: export_method — development | ad-hoc | app-store | enterprise (default: development)

### ios upload_testflight

```sh
[bundle exec] fastlane ios upload_testflight
```

Build IPA and upload to TestFlight (auto build number + release notes)

Options: skip_build:true — upload existing IPA only

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Create app in App Store Connect + Developer Portal

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload App Store screenshots only (no binary) — from store/screenshots/

### ios prune_excess_certificates_for_ci

```sh
[bundle exec] fastlane ios prune_excess_certificates_for_ci
```

Revoke excess API-created Development certs on CI (frees Apple cert slots)

### ios setup_appstore_signing

```sh
[bundle exec] fastlane ios setup_appstore_signing
```

Setup App Store distribution certificate + provisioning profile

### ios increment_build

```sh
[bundle exec] fastlane ios increment_build
```

Increment build number in Xcode project only

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean iOS build artifacts

----


## Android

### android build_debug

```sh
[bundle exec] fastlane android build_debug
```

Build Android debug APK

### android build_release_apk

```sh
[bundle exec] fastlane android build_release_apk
```

Build Android release APK

### android build_release_bundle

```sh
[bundle exec] fastlane android build_release_bundle
```

Build Android release App Bundle

### android clean

```sh
[bundle exec] fastlane android clean
```

Clean Android build artifacts

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
