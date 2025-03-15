#!/bin/bash

set -eo pipefail
echo "$APPSTORE_API_KEY" > authkey.p8
xcrun altool --upload-app -t ios -f build/mindLAMP\ 2.ipa --apiKey $APPSTORE_KEY_ID --apiIssuer $APPSTORE_ISSUER_ID --verbose
