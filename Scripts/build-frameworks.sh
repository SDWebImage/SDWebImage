#!/bin/bash

XCODE_VERSION=$(xcodebuild -version | head -n 1| awk -F ' ' '{print $2}')
XCODE_VERSION_MAJOR=$(echo $XCODE_VERSION | awk -F '.' '{print $1}')
if [ -z "$SRCROOT" ]
then
    SRCROOT=$(pwd)
fi

mkdir -p "${SRCROOT}/build"
declare -a PLATFORMS=("iphoneos" "iphonesimulator" "macosx" "appletvos" "appletvsimulator" "watchos" "watchsimulator" "maccatalyst")

if [ $XCODE_VERSION_MAJOR -ge 15 ]
then
    PLATFORMS+=("xros")
    PLATFORMS+=("xrsimulator")
fi

for CURRENT_PLATFORM in "${PLATFORMS[@]}"
do
    if [[ $CURRENT_PLATFORM == *"simulator" ]]; then
        xcodebuild build -project "SDWebImage.xcodeproj" -sdk "${CURRENT_PLATFORM}" -scheme "SDWebImage" -configuration "Debug" -derivedDataPath "${SRCROOT}/build/DerivedData" CONFIGURATION_BUILD_DIR="${SRCROOT}/build/${CURRENT_PLATFORM}/"
    else
    # macOS Catalyst
    if [[ $CURRENT_PLATFORM == "maccatalyst" ]]; then
        if [[ $XCODE_VERSION_MAJOR -lt 11 ]]; then
            # Xcode 10 does not support macOS Catalyst
            continue
        else
            xcodebuild archive -project "SDWebImage.xcodeproj" -scheme "SDWebImage" -configuration "Release" -destination 'platform=macOS,arch=x86_64,variant=Mac Catalyst' -archivePath "${SRCROOT}/build/${CURRENT_PLATFORM}/SDWebImage.xcarchive" -derivedDataPath "${SRCROOT}/build/DerivedData" SKIP_INSTALL=NO
        fi
    else
        xcodebuild archive -project "SDWebImage.xcodeproj" -sdk "${CURRENT_PLATFORM}" -scheme "SDWebImage" -configuration "Release" -archivePath "${SRCROOT}/build/${CURRENT_PLATFORM}/SDWebImage.xcarchive" SKIP_INSTALL=NO
    fi
    mv "${SRCROOT}/build/${CURRENT_PLATFORM}/SDWebImage.xcarchive/Products/Library/Frameworks/SDWebImage.framework" "${SRCROOT}/build/${CURRENT_PLATFORM}/"
    mv "${SRCROOT}/build/${CURRENT_PLATFORM}/SDWebImage.xcarchive/dSYMs/SDWebImage.framework.dSYM" "${SRCROOT}/build/${CURRENT_PLATFORM}/"
    rm -rf "${SRCROOT}/build/${CURRENT_PLATFORM}/SDWebImage.xcarchive/"
    fi
done
