#!/usr/bin/env bash
# One-shot: register Play service-account JSON + (optional) upload internal AAB.
#
# 1) Play Console → Settings → API access → link Cloud project
# 2) Create service account → key JSON download
# 3) Invite that SA email in Play Console with "Release to testing tracks" (or Admin)
# 4) Save JSON to:
#      ~/.hermes/secrets/clipval/play-store-key.json
#    OR pass path: ./scripts/play_ci_setup_and_upload.sh /path/to.json
# 5) Run this script — sets GitHub secrets and runs Fastlane upload_internal
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_JSON="${HOME}/.hermes/secrets/clipval/play-store-key.json"
JSON_PATH="${1:-$DEFAULT_JSON}"
REPO="${GITHUB_REPOSITORY:-yky32/clipvault-app}"

if [[ ! -f "$JSON_PATH" ]]; then
  cat <<EOF
Missing Play service-account JSON: $JSON_PATH

Do this once in browser (cannot be fully automated without your Google login):

  1. https://play.google.com/console → Setup → API access
  2. Link a Google Cloud project (create if needed)
  3. https://console.cloud.google.com/iam-admin/serviceaccounts
     → Create service account (e.g. clipval-play-upload)
     → Keys → Add key → JSON → download
  4. Back to Play Console → API access → invite that SA email
     Permissions: Admin OR "Release apps to testing tracks" + "View app information"
  5. Save the JSON to:
       $DEFAULT_JSON
  6. Re-run:
       $0

EOF
  exit 2
fi

mkdir -p "$(dirname "$DEFAULT_JSON")"
if [[ "$JSON_PATH" != "$DEFAULT_JSON" ]]; then
  cp "$JSON_PATH" "$DEFAULT_JSON"
  chmod 600 "$DEFAULT_JSON"
  JSON_PATH="$DEFAULT_JSON"
fi

echo "→ Setting GitHub secret PLAY_STORE_JSON_KEY_BASE64 on $REPO"
base64 -i "$JSON_PATH" | gh secret set PLAY_STORE_JSON_KEY_BASE64 -R "$REPO"
printf 'true' | gh secret set PLAY_STORE_JSON_KEY_IS_BASE64 -R "$REPO"

# Also for local fastlane
export PLAY_STORE_JSON_KEY_PATH="$JSON_PATH"
export PLAY_STORE_JSON_KEY_IS_BASE64=false

# Ensure Android keystore env if present
if [[ -f "${HOME}/.hermes/secrets/clipval/android-keystore.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "${HOME}/.hermes/secrets/clipval/android-keystore.env"
  set +a
fi

echo "→ Secrets set. Triggering GitHub Actions Deploy Android (upload_play=true)…"
gh workflow run "Deploy Android" -R "$REPO" -f upload_play=true -f skip_debug=true

echo ""
echo "Watch: gh run list -R $REPO --workflow='Deploy Android' --limit 3"
echo "Or local upload without waiting for CI:"
echo "  cd $ROOT/ios && bundle exec fastlane android upload_internal"
