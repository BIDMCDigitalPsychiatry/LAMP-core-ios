#!/bin/bash

set -eo pipefail
echo "${{ secrets.APPSTORE_API_KEY_BASE64 }}" | base64 --decode > AuthKey.p8
export APPSTORE_KEY_ID = "V7878248C8"
export APPSTORE_ISSUER_ID = "69a6de90-0c7b-47e3-e053-5b8c7c11a4d1"
xcrun altool --upload-app -t ios -f build/mindLAMP\ 2.ipa \
      --apiKey $APPSTORE_KEY_ID \
      --apiIssuer $APPSTORE_ISSUER_ID \
      --apiKeyPath AuthKey.p8 \
      --verbose
