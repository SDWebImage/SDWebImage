#!/bin/bash

set -e
set -o pipefail

if [[ -z "$XCODE_VERSION_MAJOR" ]]
then
    XCODE_VERSION_MAJOR=$(xcodebuild -showBuildSettings | awk -F= '/XCODE_VERSION_MAJOR/{x=$NF; gsub(/[^0-9]/,"",x); print int(x)}')
fi
if [[ -z "$XCODE_VERSION_MINOR" ]]  
then
    XCODE_VERSION_MINOR=$(xcodebuild -showBuildSettings | awk -F= '/XCODE_VERSION_MINOR/{x=$NF; gsub(/[^0-9]/,"",x); print int(x)}')
fi
XCODE_MAJOR=$(($XCODE_VERSION_MAJOR / 100))
XCODE_MINOR=$(($XCODE_VERSION_MINOR / 10))
XCODE_MINOR=$(($XCODE_MINOR % 10))
echo "XCODE_MAJOR=$XCODE_MAJOR"
echo "XCODE_MINOR=$XCODE_MINOR"
if [ -z "$SRCROOT" ]
then
    SRCROOT=$(pwd)
fi

if [ $XCODE_MAJOR -lt 11 ]
then
    echo "Xcode 10 does not support xcframework. You can still use the individual framework for each platform."
    open -a Finder "${SRCROOT}/build/"
    exit 0
fi

mkdir -p "${SRCROOT}/build"
PLATFORMS=("iOS" "iOSSimulator" "macOS" "tvOS" "tvOSSimulator" "watchOS" "watchOSSimulator")

if [ $XCODE_MAJOR -ge 11 ]
then
    PLATFORMS+=("macCatalyst")
fi

if [[ ($XCODE_MAJOR -gt 15) || ($XCODE_MAJOR -eq 15 && $XCODE_MINOR -ge 2) ]]
then
    PLATFORMS+=("visionOS")
    PLATFORMS+=("visionOSSimulator")
fi

COMMAND_ARGS=""
for CURRENT_PLATFORM in "${PLATFORMS[@]}"
do
    COMMAND_ARGS="${COMMAND_ARGS} -framework ${SRCROOT}/build/${CURRENT_PLATFORM}/SDWebImage.framework"
    if [[ $MACH_O_TYPE != "staticlib" ]]; then
        COMMAND_ARGS="${COMMAND_ARGS} -debug-symbols ${SRCROOT}/build/${CURRENT_PLATFORM}/SDWebImage.framework.dSYM"
    fi
done

# Combine XCFramework
echo "Create XCFramework"
xcodebuild -create-xcframework $COMMAND_ARGS -output "${SRCROOT}/build/SDWebImage.xcframework"
