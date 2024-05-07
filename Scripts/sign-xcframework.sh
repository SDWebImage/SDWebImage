#!/bin/bash

set -e
set -x
set -o pipefail

if [ -z "$SRCROOT" ]
then
    SRCROOT=$(pwd)
fi

# Self-sign XCFramework
if [ -z $CODESIGN_KEY_BASE64 ]; then
    echo "Ignore Codesign XCFramework! You must sign SDWebImage before shipping to App Store. See: https://developer.apple.com/support/third-party-SDK-requirements"
    exit 0
fi

KEYCHAIN=~/Library/Keychains/ios.keychain
KEYCHAIN_PASSWORD=SDWebImage
CODESIGN_IDENTIFY_NAME=SDWebImage\ Signing\ Certificate
KEY_PASSWORD=""

echo $CODESIGN_KEY_BASE64 | base64 -D > "$(PWD)/Certificate/${CODESIGN_IDENTIFY_NAME}.p12"

security create-keychain -p "$KEYCHAIN_PASSWORD" ios.keychain
security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN

security import "$(PWD)/Certificate/${CODESIGN_IDENTIFY_NAME}.cer" -k $KEYCHAIN -T /usr/bin/codesign
security import "$(PWD)/Certificate/${CODESIGN_IDENTIFY_NAME}.p12" -k $KEYCHAIN -P "$KEY_PASSWORD" -T /usr/bin/codesign
security list-keychains -s ios.keychain
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" $KEYCHAIN

echo "Codesign XCFramework"
/usr/bin/codesign --force --timestamp -v --sign "SDWebImage Signing Certificate" "${SRCROOT}/build/SDWebImage.xcframework"

rm -rf "$(PWD)/Certificate/${CODESIGN_IDENTIFY_NAME}.p12"
security delete-keychain ios.keychain