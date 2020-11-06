#!/bin/bash

set -eo pipefail

xcrun altool --upload-app -t ios -f build/mindLAMP\ 2.ipa -u "$APPLEID_USERNAME" -p "$APPLEID_PASSWORD" --verbose