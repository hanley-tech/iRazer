#!/bin/bash
# Build iRazer.app and package it into a distributable DMG.
#
# NOTE ON SIGNING: this produces an *ad-hoc signed* (unsigned) app. Users will
# see a Gatekeeper warning on first launch and must right-click → Open (once).
# To ship without that warning you need an Apple Developer ID ($99/yr) to sign
# and notarize — see the comment at the bottom.
set -euo pipefail
cd "$(dirname "$0")/.."

./Scripts/make-app.sh

VERSION=$(defaults read "$PWD/build/iRazer.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0.1.0)
DMG="build/iRazer-${VERSION}.dmg"
STAGE="build/dmg"

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R build/iRazer.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"      # drag-to-install target

hdiutil create -volname "iRazer" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
echo "Built $DMG"

# ---------------------------------------------------------------------------
# To sign + notarize (removes the Gatekeeper warning), with a paid Developer ID:
#   codesign --deep --force --options runtime \
#     --sign "Developer ID Application: <Your Name> (<TEAMID>)" build/iRazer.app
#   xcrun notarytool submit "$DMG" --apple-id <id> --team-id <TEAMID> \
#     --password <app-specific-pw> --wait
#   xcrun stapler staple "$DMG"
# ---------------------------------------------------------------------------
