#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="$ROOT/.cache"
ICONSET="$CACHE/CodePad16.iconset"
mkdir -p "$CACHE/clang" "$ICONSET"
CLANG_MODULE_CACHE_PATH="$CACHE/clang" swiftc \
  -module-cache-path "$CACHE/clang" \
  -Xcc "-fmodules-cache-path=$CACHE/clang" \
  "$ROOT/scripts/render-icon.swift" \
  -o "$CACHE/render-icon"
"$CACHE/render-icon" "$CACHE/cat-icon-1024.png"

make_size() {
  local size="$1" name="$2"
  sips -z "$size" "$size" "$CACHE/cat-icon-1024.png" --out "$ICONSET/$name" >/dev/null
}
make_size 16 icon_16x16.png
make_size 32 icon_32x32.png
make_size 64 icon_32x32@2x.png
make_size 128 icon_128x128.png
make_size 256 icon_256x256.png
make_size 512 icon_512x512.png
make_size 1024 icon_512x512@2x.png
python3 "$ROOT/scripts/assemble-icns.py" "$ICONSET" "$ROOT/Resources/CodePad16.icns"
printf 'Wrote %s\n' "$ROOT/Resources/CodePad16.icns"
