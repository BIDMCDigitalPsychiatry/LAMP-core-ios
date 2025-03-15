#!/bin/bash

set -eo pipefail

# Create directory
mkdir -p "$HOME/private_keys"

# Define file path correctly
APPSTORE_API_KEY_PATH="$HOME/private_keys/$APPSTORE_API_KEY_FILENAME"

# Decode and store API key
echo "$APPSTORE_API_KEY_BASE64" | base64 --decode > $APPSTORE_API_KEY_PATH
xcrun altool --upload-app -t ios -f build/mindLAMP\ 2.ipa \
      --apiKey $APPSTORE_KEY_ID \
      --apiIssuer $APPSTORE_ISSUER_ID \
      --apiKeyPath $APPSTORE_API_KEY_PATH \
      --verbose
rm -f "$APPSTORE_API_KEY_PATH"
