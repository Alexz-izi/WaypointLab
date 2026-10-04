#!/usr/bin/env bash
# build_ipa.sh - Waypoint Lab Cloud / Local Compilation Script
# Builds WaypointLab.app using xcodebuild and packages it into an unsigned WaypointLab.ipa for SideStore.

set -euo pipefail

echo "=================================================="
echo "  Waypoint Lab - iOS IPA Build & Package Script   "
echo "=================================================="

BUILD_DIR="build_output"
OUTPUT_IPA="WaypointLab.ipa"

# 1. Clean previous build output
rm -rf "$BUILD_DIR" "$OUTPUT_IPA" Payload

# 2. Run xcodebuild targeting iOS device architecture without signing requirement
echo "[1/3] Compiling native arm64 application bundle..."
xcodebuild \
  -project WaypointLab.xcodeproj \
  -scheme WaypointLab \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

# 3. Locate compiled .app directory
echo "[2/3] Locating compiled WaypointLab.app..."
APP_BUNDLE=$(find "$BUILD_DIR" -name "WaypointLab.app" -type d | head -n 1)

if [[ -z "$APP_BUNDLE" || ! -d "$APP_BUNDLE" ]]; then
  echo "Error: WaypointLab.app bundle was not created." >&2
  exit 1
fi

echo "Found application bundle: $APP_BUNDLE"

# 4. Package into standard IPA archive
echo "[3/3] Assembling IPA archive..."
mkdir -p Payload
cp -r "$APP_BUNDLE" Payload/
zip -r -9 "$OUTPUT_IPA" Payload
rm -rf Payload

echo "=================================================="
echo "  SUCCESS: Generated $OUTPUT_IPA"
echo "  File size: $(du -h "$OUTPUT_IPA" | cut -f1)"
echo "=================================================="
