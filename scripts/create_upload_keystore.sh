#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="$ROOT/android/upload-keystore.jks"
PROPS="$ROOT/android/key.properties"
EXAMPLE="$ROOT/android/key.properties.example"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore already exists: $KEYSTORE"
  exit 1
fi

echo "Creating upload keystore at: $KEYSTORE"
echo "You will be prompted for keystore and key passwords — save them securely."
echo

keytool -genkey -v \
  -keystore "$KEYSTORE" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

if [[ ! -f "$PROPS" ]]; then
  cp "$EXAMPLE" "$PROPS"
  echo
  echo "Created $PROPS — edit it with your keystore passwords before building."
fi

echo
echo "Done. Next:"
echo "  1. Edit android/key.properties with your passwords"
echo "  2. flutter build appbundle --release"
