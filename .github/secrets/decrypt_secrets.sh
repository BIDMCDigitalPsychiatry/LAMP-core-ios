#!/bin/sh
set -eo pipefail

echo "Start Import"

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindlamp2_AppStore_Profile.mobileprovision .github/secrets/mindlamp2_AppStore_Profile.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/Certificates.p12 .github/secrets/Certificates.p12.gpg

echo "Imported"

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp .github/secrets/mindlamp2_AppStore_Profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindlamp2_AppStore_Profile.mobileprovision

echo "Copied"

security create-keychain -p "" build.keychain
security import .github/secrets/Certificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain