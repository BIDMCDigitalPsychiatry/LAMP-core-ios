#!/bin/bash

set -eo pipefail

xcodebuild -project mindLAMP.xcodeproj \
            -scheme mindLAMP\ \(Staging\) \
            -configuration Release\ \(Staging\) \
            -archivePath $PWD/build/mindLAMP.xcarchive \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
            clean archive | xcpretty
