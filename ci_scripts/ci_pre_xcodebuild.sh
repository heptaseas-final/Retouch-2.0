#!/bin/sh
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"
CUSTOM_BUILD_NUMBER=$((CI_BUILD_NUMBER - 44))

echo "change build number from $CI_BUILD_NUMBER to $CUSTOM_BUILD_NUMBER"
xcrun agvtool new-version -all $CUSTOM_BUILD_NUMBER
