#!/usr/bin/env bash
# Create Android release keystore + android/key.properties for ClipVal.
# Run once locally. Never commit .jks or key.properties.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE="$ANDROID_DIR/clipval-upload.jks"
PROPS="$ANDROID_DIR/key.properties"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore already exists: $KEYSTORE"
  echo "Refusing to overwrite. Delete it manually if you really want a new one."
  exit 1
fi

read -r -s -p "Keystore password: " STORE_PASS
echo
read -r -s -p "Key password (enter = same): " KEY_PASS
echo
KEY_PASS="${KEY_PASS:-$STORE_PASS}"
ALIAS="${ANDROID_KEY_ALIAS:-clipval}"

keytool -genkeypair \
  -v \
  -keystore "$KEYSTORE" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=ClipVal, OU=WY Limited, O=WY Limited, L=Hong Kong, ST=HK, C=HK"

cat > "$PROPS" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=clipval-upload.jks
EOF
chmod 600 "$PROPS" "$KEYSTORE"

echo ""
echo "OK"
echo "  keystore: $KEYSTORE"
echo "  props:    $PROPS"
echo ""
echo "Add to .gitignore (should already be ignored):"
echo "  android/key.properties"
echo "  android/*.jks"
echo ""
echo "GitHub secrets for CI (base64 keystore):"
echo "  base64 -i android/clipval-upload.jks | pbcopy"
echo "  → ANDROID_KEYSTORE_BASE64"
echo "  → ANDROID_KEYSTORE_PASSWORD"
echo "  → ANDROID_KEY_ALIAS=$ALIAS"
echo "  → ANDROID_KEY_PASSWORD"
