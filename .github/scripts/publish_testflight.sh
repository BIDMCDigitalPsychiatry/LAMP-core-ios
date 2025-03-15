#!/bin/bash

set -eo pipefail
echo "$APPSTORE_API_KEY_BASE64" | base64 --decode > AuthKey.p8
xcrun altool --upload-app -t ios -f build/mindLAMP\ 2.ipa \
      --apiKey $APPSTORE_KEY_ID \
      --apiIssuer $APPSTORE_ISSUER_ID \
      --apiKeyPath AuthKey.p8 \
      --verbose
rm -f AuthKey.p8
