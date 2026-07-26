#!/usr/bin/env bash
# One-shot TestFlight upload for ClipVal (wraps Fastlane like Depozio/Triftly).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/ios"

if [ ! -f Gemfile ]; then
  echo "Missing ios/Gemfile" >&2
  exit 1
fi

# Prefer rbenv Ruby 2.6 (same as Triftly / install_gems_and_pods.sh)
if [ -x "$HOME/.rbenv/bin/rbenv" ] || command -v rbenv >/dev/null 2>&1; then
  export PATH="${HOME}/.rbenv/bin:${HOME}/.rbenv/shims:${PATH}"
  eval "$(rbenv init -)" 2>/dev/null || true
  if [ -f .ruby-version ]; then
    rbenv shell "$(tr -d '\n' < .ruby-version)" 2>/dev/null || true
  fi
fi

if [ ! -d vendor/bundle ] && [ ! -f Gemfile.lock ]; then
  echo "→ first-time gem/pod install"
  "$ROOT/ios/install_gems_and_pods.sh"
fi

echo "→ $(ruby -v)"
echo "→ fastlane ios upload_testflight $*"
bundle exec fastlane ios upload_testflight "$@"