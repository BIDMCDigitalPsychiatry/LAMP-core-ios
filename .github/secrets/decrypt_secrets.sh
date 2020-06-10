#!/bin/sh
set -eo pipefail

echo "Start Import"

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/Certificates.p12 .github/secrets/Certificates.p12.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/PushCertificates.p12 .github/secrets/PushCertificates.p12.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP_2.mobileprovision .github/secrets/mindLAMP_2.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP_2_Notification_Extension_AppStore.mobileprovision .github/secrets/mindLAMP_2_Notification_Extension_AppStore.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP_2_Notification_Service_AppStore.mobileprovision .github/secrets/mindLAMP_2_Notification_Service_AppStore.mobileprovision.gpg

echo "Imported"

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp .github/secrets/mindLAMP_2.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP_2.mobileprovision
cp .github/secrets/mindLAMP_2_Notification_Extension_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP_2_Notification_Extension_AppStore.mobileprovision
cp .github/secrets/mindLAMP_2_Notification_Service_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP_2_Notification_Service_AppStore.mobileprovision

echo "Copied"

security create-keychain -p "" build.keychain
security import .github/secrets/Certificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A
security import .github/secrets/PushCertificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain
