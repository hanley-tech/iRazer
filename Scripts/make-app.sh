#!/bin/bash
# Assemble iRazer.app from the SPM release build.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --build-system native 2>/dev/null || swift build -c release

APP=build/iRazer.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cp .build/release/iRazer "$APP/Contents/MacOS/iRazer"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>iRazer</string>
    <key>CFBundleIdentifier</key><string>ai.taiso.irazer</string>
    <key>CFBundleName</key><string>iRazer</string>
    <key>CFBundleDisplayName</key><string>iRazer</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Open source — MIT</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
