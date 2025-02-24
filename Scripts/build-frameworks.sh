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
if [[ -z "$SRCROOT" ]]
then
    SRCROOT=$(pwd)
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

for CURRENT_PLATFORM in "${PLATFORMS[@]}"
do
    DESTINATION="generic/platform=${CURRENT_PLATFORM}"

    # macOS Catalyst
    if [[ $CURRENT_PLATFORM == "macCatalyst" ]]; then
        DESTINATION="generic/platform=macOS,variant=Mac Catalyst"
    fi

    # Simulator
    if [[ $CURRENT_PLATFORM == *Simulator ]]; then
        CURRENT_PLATFORM_OS=${CURRENT_PLATFORM%Simulator}
        DESTINATION="generic/platform=${CURRENT_PLATFORM_OS} Simulator"
    fi

    if [[ $MACH_O_TYPE == "staticlib" ]]; then
        XCCCONFIG_PATH="${SRCROOT}/Configs/Static.xcconfig"
    else
        XCCCONFIG_PATH="${SRCROOT}/Configs/Dynamic.xcconfig"
    fi

    xcodebuild build -project "SDWebImage.xcodeproj" -destination "${DESTINATION}" -scheme "SDWebImage" -configuration "Release" -xcconfig "${XCCCONFIG_PATH}" -derivedDataPath "${SRCROOT}/build/DerivedData" CONFIGURATION_BUILD_DIR="${SRCROOT}/build/${CURRENT_PLATFORM}/"
done
