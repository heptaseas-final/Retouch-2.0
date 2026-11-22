#!/bin/sh
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"
brew install xcodegen
xcodegen generate
mkdir -p Retouch.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
cp Config/Package.resolved Retouch.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved