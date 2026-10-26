#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/dist/CodePad.app"
OUTPUT="$ROOT/dist/CodePad-macOS-arm64.dmg"
STAGING="$ROOT/.cache/dmg-staging"
RAW_IMAGE="$ROOT/.cache/CodePad-raw.dmg"

if [[ ! -d "$APP" ]]; then
  echo "Build the app first with ./scripts/build-app.sh" >&2
  exit 1
fi

ARCHS="$(lipo -archs "$APP/Contents/MacOS/CodePad")"
if [[ "$ARCHS" != "arm64" ]]; then
  echo "Expected an Apple Silicon arm64 app, found: $ARCHS" >&2
  exit 1
fi

rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/CodePad.app"
ln -s /Applications "$STAGING/Applications"
rm -f "$RAW_IMAGE" "$OUTPUT"
# Building an HFS+ image directly avoids hdiutil create's dependency on
# DiskManagement to attach a temporary image. Convert it to compressed UDIF.
hdiutil makehybrid \
  -hfs \
  -default-volume-name "CodePad" \
  -o "$RAW_IMAGE" \
  "$STAGING"
hdiutil convert "$RAW_IMAGE" -format UDZO -o "$OUTPUT"
hdiutil verify "$OUTPUT"
rm -rf "$STAGING"
rm -f "$RAW_IMAGE"
echo "Created $OUTPUT"
