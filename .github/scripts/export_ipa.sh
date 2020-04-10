#!/bin/bash

set -eo pipefail

xcodebuild -archivePath $PWD/build/mindLAMP.xcarchive \
            -exportOptionsPlist mindLAMP/exportOptions.plist \
            -exportPath $PWD/build \
            -allowProvisioningUpdates \
            -exportArchive | xcpretty