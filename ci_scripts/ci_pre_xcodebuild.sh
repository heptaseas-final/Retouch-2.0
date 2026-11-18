#!/bin/sh
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Karena Next Build Number saat ini 42, kurangi 40 agar menjadi 2
CUSTOM_BUILD_NUMBER=$((CI_BUILD_NUMBER - 40))

echo "Mengubah build number dari $CI_BUILD_NUMBER menjadi $CUSTOM_BUILD_NUMBER"
xcrun agvtool new-version -all $CUSTOM_BUILD_NUMBER
