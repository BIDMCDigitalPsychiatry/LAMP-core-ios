#!/bin/sh
set -eo pipefail

echo "Start Import"

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/Certificates.p12 .github/secrets/Certificates.p12.gpg

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP2.mobileprovision .github/secrets/mindLAMP2.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP2_Custom_Notification_Extension.mobileprovision .github/secrets/mindLAMP2_Custom_Notification_Extension.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP2_Notification_Service.mobileprovision .github/secrets/mindLAMP2_Notification_Service.mobileprovision.gpg

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP2_WatchApp_Extension.mobileprovision .github/secrets/mindLAMP2_WatchApp_Extension.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP2_WatchApp.mobileprovision .github/secrets/mindLAMP2_WatchApp.mobileprovision.gpg

echo "Imported"

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp .github/secrets/mindLAMP2_2022.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP2.mobileprovision
cp .github/secrets/mindLAMP2_Custom_Notification_Extension_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP2_Custom_Notification_Extension.mobileprovision
cp .github/secrets/mindLAMP2_Notification_Service_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP2_Notification_Service.mobileprovision

cp .github/secrets/mindLAMP2_WatchApp_Extension_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP2_WatchApp_Extension.mobileprovision
cp .github/secrets/mindLAMP2_WatchApp_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP2_WatchApp.mobileprovision

echo "Copied"

security create-keychain -p "" build.keychain
security import .github/secrets/Certificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain
