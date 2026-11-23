#!/bin/sh
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"
printf 'MIXPANEL_TOKEN_DEV = %s\nMIXPANEL_TOKEN_PROD = %s\n' "$MIXPANEL_TOKEN_DEV" "$MIXPANEL_TOKEN_PROD" > Config/Secrets.xcconfig
brew install xcodegen
xcodegen generate
mkdir -p Retouch.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
cp Config/Package.resolved Retouch.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved