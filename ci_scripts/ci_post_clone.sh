#!/bin/bash
set -e

echo "Post-clone script running..."
echo "Repository path: $CI_PRIMARY_REPOSITORY_PATH"

# Install XcodeGen and generate .xcodeproj
brew install xcodegen
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "Xcode Cloud build ready!"
