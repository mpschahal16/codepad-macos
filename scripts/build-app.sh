#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p "$ROOT/.cache/clang" "$ROOT/.cache/swiftpm" "$ROOT/.cache/config" "$ROOT/.cache/security"
SWIFT_BUILD_FLAGS=(
  --configuration release \
  --cache-path "$ROOT/.cache/swiftpm" \
  --config-path "$ROOT/.cache/config" \
  --security-path "$ROOT/.cache/security" \
  --scratch-path "$ROOT/.build" \
  --manifest-cache local \
  --disable-dependency-cache \
  -debug-info-format none \
  -Xswiftc -module-cache-path -Xswiftc "$ROOT/.cache/clang" \
  -Xcc "-fmodules-cache-path=$ROOT/.cache/clang"
)
if [[ "${CODEPAD_ALLOW_UNSANDBOXED_BUILD:-0}" == "1" ]]; then
  SWIFT_BUILD_FLAGS+=(--disable-sandbox)
fi
CLANG_MODULE_CACHE_PATH="$ROOT/.cache/clang" swift build "${SWIFT_BUILD_FLAGS[@]}"
APP="$ROOT/dist/CodePad.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/CodePad" "$APP/Contents/MacOS/CodePad"
cp "$ROOT/Resources/CodePad.icns" "$APP/Contents/Resources/CodePad.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>CodePad</string>
  <key>CFBundleIconFile</key><string>CodePad</string>
  <key>CFBundleIdentifier</key><string>org.mpschahal16.codepad</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>CodePad</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleSignature</key><string>????</string>
  <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
  <key>CFBundleShortVersionString</key><string>0.0.2</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST
printf 'APPL????' > "$APP/Contents/PkgInfo"
codesign --force --deep --sign - --timestamp=none "$APP"
printf 'Built %s\n' "$APP"
