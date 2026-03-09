#!/bin/bash
set -e

echo "Post-clone script running..."
echo "Repository path: $CI_PRIMARY_REPOSITORY_PATH"

# Install XcodeGen from GitHub release
XCODEGEN_VERSION="2.42.0"
curl -fsSL "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip" -o /tmp/xcodegen.zip
unzip -o /tmp/xcodegen.zip -d /tmp/xcodegen
cp /tmp/xcodegen/bin/xcodegen /usr/local/bin/xcodegen
chmod +x /usr/local/bin/xcodegen

# Generate .xcodeproj
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "Xcode Cloud build ready!"
