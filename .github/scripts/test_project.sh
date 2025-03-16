#!/bin/bash

set -eo pipefail

DEVICE=$(xcrun simctl list devices available | grep -m 1 "iPhone" | awk -F '[()]' '{print $2}')
echo "Selected device: $DEVICE"
xcodebuild test -project mindLAMP.xcodeproj -scheme mindLAMP -destination "platform=iOS Simulator,id=$DEVICE"
