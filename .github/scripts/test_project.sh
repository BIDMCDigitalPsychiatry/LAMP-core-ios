#!/bin/bash

set -eo pipefail

xcodebuild test -project mindLAMP.xcodeproj -scheme mindLAMP -destination 'platform=iOS Simulator,OS=latest'
