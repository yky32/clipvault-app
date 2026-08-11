# ClipVal — GitHub Actions → TestFlight

Automated iOS TestFlight deploy, aligned with **Triftly** (`yky32/triftly-app`).

## Flow

```
push to main  →  Deploy workflow
  1. flutter pub get + pod install
  2. Import Apple Distribution .p12 (secret)
  3. Fetch/create App Store provisioning profile for com.clipval
  4. Bump pubspec build number, commit + push [skip ci]
  5. flutter build ipa (manual signing)
  6. upload_to_testflight (App Store Connect API key)
```

Manual: **Actions → Deploy → Run workflow**

## Required GitHub secrets

Repo: **https://github.com/yky32/clipvault-app/settings/secrets/actions**

Copy the **same values** from Triftly (same Apple team `3G34999H3A`):

| Secret | Purpose |
|--------|---------|
| `APP_STORE_CONNECT_API_KEY_ID` | ASC API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | ASC Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | `.p8` private key body (PEM text; `\n` ok) |
| `IOS_DISTRIBUTION_CERT_BASE64` | Base64 of Apple Distribution `.p12` |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | Password for that `.p12` |
| `GH_PAT` | (Recommended) PAT with `repo` so build-number commits push cleanly |

Optional (not needed for ClipVal MVP):

| Secret | Notes |
|--------|--------|
| `FASTLANE_USER` | Local/legacy Apple ID auth only |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | Local/legacy |

### One-shot copy from Triftly (local machine)

If `gh` is logged in and you have access to both repos:

```bash
# Example — re-set from values you already have in 1Password / local env
# (do not paste secrets into chat)

gh secret set APP_STORE_CONNECT_API_KEY_ID -R yky32/clipvault-app < value
gh secret set APP_STORE_CONNECT_ISSUER_ID -R yky32/clipvault-app < value
gh secret set APP_STORE_CONNECT_API_KEY_CONTENT -R yky32/clipvault-app < path/to/AuthKey.p8
gh secret set IOS_DISTRIBUTION_CERT_BASE64 -R yky32/clipvault-app < <(base64 -i dist.p12)
gh secret set IOS_DISTRIBUTION_CERT_PASSWORD -R yky32/clipvault-app < value
gh secret set GH_PAT -R yky32/clipvault-app < value
```

## App Store Connect checklist

1. App ID registered: **`com.clipval`** (done)
2. App created: **ClipVal** with that Bundle ID  
   (or first CI run can attempt `create_app` via Fastlane)
3. Team: **3G34999H3A**

## Local TestFlight (same Fastlane as CI)

```bash
./ios/install_gems_and_pods.sh
cd ios && bundle exec fastlane ios upload_testflight
# or
./scripts/testflight.sh
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Missing secrets | Add table above to clipvault-app Actions secrets |
| `MAC verification failed` on p12 | Re-export Distribution `.p12` from Keychain Access |
| App not found | Create ClipVal in ASC with bundle `com.clipval` |
| Build number conflict | Re-run Deploy; Fastlane bumps `pubspec.yaml` |
| Run cancelled mid-flight | New push to `main` cancels previous (concurrency) — wait for finish |
| Signing identity missing | `IOS_DISTRIBUTION_CERT_*` must match cert on developer.apple.com |

## Golden rules (same as Triftly)

- One Distribution cert on the portal for the team  
- Never commit `.p12` / `.p8`  
- Wait for Deploy to finish before the next merge to `main`

## CloudKit / iCloud (gate)

TestFlight uses CloudKit **Production**. Deploying schema is **not** part of this workflow.

Before enabling iCloud sync for testers:

1. Follow [`CLOUDKIT_DEPLOY_CHECKLIST.md`](./CLOUDKIT_DEPLOY_CHECKLIST.md)
2. Confirm Production has `ClipItem`, `Category`, `VaultMeta`
3. Otherwise TF shows schema errors (CLIPVAL-CK-001)

