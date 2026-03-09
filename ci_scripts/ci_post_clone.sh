#!/bin/bash
set -e

echo "Downloading XcodeGen..."
curl -sL https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip -o /tmp/xcodegen.zip
unzip -q /tmp/xcodegen.zip -d /tmp

echo "Generating Xcode project..."
/tmp/xcodegen/bin/xcodegen generate --spec "$CI_PRIMARY_REPOSITORY_PATH/project.yml" --project "$CI_PRIMARY_REPOSITORY_PATH"

echo "Xcode project generated successfully!"
