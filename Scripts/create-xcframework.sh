#!/bin/bash

set -e
set -o pipefail

XCODE_VERSION=$(xcodebuild -version | head -n 1| awk -F ' ' '{print $2}')
XCODE_VERSION_MAJOR=$(echo $XCODE_VERSION | awk -F '.' '{print $1}')
XCODE_VERSION_MINOR=$(echo $XCODE_VERSION | awk -F '.' '{print $2}')
XCODE_VERSION_PATCH=$(echo $XCODE_VERSION | awk -F '.' '{print $3}')
if [ -z "$SRCROOT" ]
then
    SRCROOT=$(pwd)
fi

if [ $XCODE_VERSION_MAJOR -lt 11 ]
then
    echo "Xcode 10 does not support xcframework. You can still use the individual framework for each platform."
    open -a Finder "${SRCROOT}/build/"
    exit 0
fi

mkdir -p "${SRCROOT}/build"
PLATFORMS=("iOS" "iOSSimulator" "macOS" "tvOS" "tvOSSimulator" "watchOS" "watchOSSimulator")

if [ $XCODE_VERSION_MAJOR -ge 11 ]
then
    PLATFORMS+=("macCatalyst")
fi

if [[ ($XCODE_VERSION_MAJOR -gt 15) || ($XCODE_VERSION_MAJOR -eq 15 && $XCODE_VERSION_MINOR -ge 2) ]]
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
