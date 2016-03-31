#!/bin/sh

PROJECT_PATH=$1
SCHEME=$2
PLATFORM=$3

DEVICE_ARCHS="armv7 arm64"
SIM_ARCHS="i386 x86_64"
VALID_ARCHS="$DEVICE_ARCHS $SIM_ARCHS"
DEVICE_SDK="iphoneos"
SIM_SDK="iphonesimulator"

if [[ -n "$PLATFORM" ]]; then
    if [ "$PLATFORM" = "tv" ]; then
        DEVICE_ARCHS="arm64"
        SIM_ARCHS="i386 x86_64"
        VALID_ARCHS="$DEVICE_ARCHS $SIM_ARCHS"
        DEVICE_SDK="appletvos"
        SIM_SDK="appletvsimulator"
    elif [ "$PLATFORM" = "watch" ]; then
        DEVICE_ARCHS="armv7k"
        SIM_ARCHS="i386 x86_64"
        VALID_ARCHS="$DEVICE_ARCHS $SIM_ARCHS"
        DEVICE_SDK="watchos"
        SIM_SDK="watchsimulator"
    fi
fi

echo "$DEVICE_SDK"

CONFIG_FILE="$(dirname $0)/build.xcconfig"
cd "$(dirname "$PROJECT_PATH")"

if [ `basename "$PROJECT_PATH"` == *.xcworkspace ]; then
    args="-workspace"
else
    args="-project"
fi

# build
set -o pipefail && xcodebuild $args "$PROJECT_PATH" -configuration Release ARCHS="$SIM_ARCHS" VALID_ARCHS="$VALID_ARCHS" CONFIGURATION_BUILD_DIR="$(pwd)/build/Release-$SIM_SDK" -scheme "$SCHEME" -sdk $SIM_SDK build | xcpretty
if [ "$?" != "0" ]; then
    exit 1
fi

# archive
set -o pipefail && xcodebuild $args "$PROJECT_PATH" -configuration Release ARCHS="$DEVICE_ARCHS" VALID_ARCHS="$VALID_ARCHS" STRIP_INSTALLED_PRODUCT=NO SKIP_INSTALL=NO DSTROOT= INSTALL_PATH="$(pwd)/build/Release-$DEVICE_SDK" -scheme "$SCHEME" -sdk $DEVICE_SDK archive | xcpretty
if [ "$?" != "0" ]; then
    exit 1
fi

cd build

output="Release-fatify"

rm -rf "$output"
mkdir "$output"

names=$( ls Release-$DEVICE_SDK/ | xargs -n1 basename)
echo $names
for name in $names; do
    if [[ -d "Release-$DEVICE_SDK/$name" ]]; then
        # .framework的静态库的情况
        filename="${name%.*}"
        cp -r "Release-$DEVICE_SDK/$name" "$output/$name"
        set -x && lipo -create "Release-$DEVICE_SDK/$name/$filename" "Release-$SIM_SDK/$name/$filename" -output "$output/$name/$filename"
    elif [[ -f "Release-$DEVICE_SDK/$name" ]]; then
        # .a单个静态库文件的情况
        set -x && lipo -create "Release-$DEVICE_SDK/$name" "Release-$SIM_SDK/$name" -output "$output/$name"
    fi
done

