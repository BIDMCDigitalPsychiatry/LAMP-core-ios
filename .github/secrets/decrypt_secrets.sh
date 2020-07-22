#!/bin/sh
set -eo pipefail

echo "Start Import"

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/Certificates.p12 .github/secrets/Certificates.p12.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/PushCertificates.p12 .github/secrets/PushCertificates.p12.gpg

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/WatchPushExtCertificates.p12 .github/secrets/WatchPushExtCertificates.p12.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/WatchAppPushCertificates.p12 .github/secrets/WatchAppPushCertificates.p12.gpg

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP_2.mobileprovision .github/secrets/mindLAMP_2.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP_2_Notification_Extension_AppStore.mobileprovision .github/secrets/mindLAMP_2_Notification_Extension_AppStore.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLAMP_2_Notification_Service_AppStore.mobileprovision .github/secrets/mindLAMP_2_Notification_Service_AppStore.mobileprovision.gpg

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLamp_2_watchkitapp_extension.mobileprovision .github/secrets/mindLamp_2_watchkitapp_extension.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output .github/secrets/mindLamp_2_watchkitapp.mobileprovision .github/secrets/mindLamp_2_watchkitapp.mobileprovision.gpg

echo "Imported"

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp .github/secrets/mindLAMP_2.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP_2.mobileprovision
cp .github/secrets/mindLAMP_2_Notification_Extension_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP_2_Notification_Extension_AppStore.mobileprovision
cp .github/secrets/mindLAMP_2_Notification_Service_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLAMP_2_Notification_Service_AppStore.mobileprovision

cp .github/secrets/mindLamp_2_watchkitapp_extension.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLamp_2_watchkitapp_extension.mobileprovision
cp .github/secrets/mindLamp_2_watchkitapp.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/mindLamp_2_watchkitapp.mobileprovision.mobileprovision

echo "Copied"

security create-keychain -p "" build.keychain
security import .github/secrets/Certificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A
security import .github/secrets/PushCertificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A

security import .github/secrets/WatchPushExtCertificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A
security import .github/secrets/WatchAppPushCertificates.p12 -t agg -k ~/Library/Keychains/build.keychain -P "$IOS_KEYS" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain
