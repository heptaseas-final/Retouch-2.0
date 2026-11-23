#!/bin/sh
set -e
if [ "$CI_XCODEBUILD_ACTION" = "test-without-building" ]; then
    echo "skip build number, no project in test-without-building"
    exit 0
fi
cd "$CI_PRIMARY_REPOSITORY_PATH"
CUSTOM_BUILD_NUMBER=$((CI_BUILD_NUMBER - 48))

echo "change build number from $CI_BUILD_NUMBER to $CUSTOM_BUILD_NUMBER"
xcrun agvtool new-version -all $CUSTOM_BUILD_NUMBER
