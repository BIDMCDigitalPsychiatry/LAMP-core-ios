#!/bin/bash

set -eo pipefail

xcodebuild -project mindLAMP.xcodeproj \
            -scheme mindLAMP\ \(Staging\) \
            -configuration Release\ \(Staging\) \
            -archivePath $PWD/build/mindLAMP.xcarchive \
            -destination "generic/platform=iOS" \
            clean archive | xcpretty
