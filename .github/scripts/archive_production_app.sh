#!/bin/bash

set -eo pipefail

xcodebuild -project mindLAMP.xcodeproj \
            -scheme mindLAMP \
            -configuration Release \
            -archivePath $PWD/build/mindLAMP.xcarchive \
            clean archive | xcpretty