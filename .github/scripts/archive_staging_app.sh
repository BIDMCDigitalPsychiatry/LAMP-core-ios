#!/bin/bash

set -eo pipefail

xcodebuild -project mindLAMP.xcodeproj \
            -scheme mindLAMP\ \(Staging\) \
            -configuration Release\ \(Staging\) \
            -archivePath $PWD/build/mindLAMP.xcarchive \
            clean archive | xcpretty
