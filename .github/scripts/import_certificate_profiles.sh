#!/bin/bash

set -eo pipefail

echo "create variables"
CERTIFICATE_PATH=$RUNNER_TEMP/build_certificate.p12
PP_PATH1=$RUNNER_TEMP/build_pp1.mobileprovision
PP_PATH2=$RUNNER_TEMP/build_pp2.mobileprovision
PP_PATH3=$RUNNER_TEMP/build_pp3.mobileprovision
PP_PATH4=$RUNNER_TEMP/build_pp4.mobileprovision
PP_PATH5=$RUNNER_TEMP/build_pp5.mobileprovision
PP_PATH6=$RUNNER_TEMP/build_pp6.mobileprovision
KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

echo "import certificate and provisioning profile from secrets"
echo -n "$BUILD_CERTIFICATE_BASE64" | base64 --decode -o $CERTIFICATE_PATH
echo -n "$BUILD_PROVISION_PROFILE1_BASE64" | base64 --decode -o $PP_PATH1
echo -n "$BUILD_PROVISION_PROFILE2_BASE64" | base64 --decode -o $PP_PATH2
echo -n "$BUILD_PROVISION_PROFILE3_BASE64" | base64 --decode -o $PP_PATH3
echo -n "$BUILD_PROVISION_PROFILE4_BASE64" | base64 --decode -o $PP_PATH4
echo -n "$BUILD_PROVISION_PROFILE5_BASE64" | base64 --decode -o $PP_PATH5
echo -n "$BUILD_PROVISION_PROFILE6_BASE64" | base64 --decode -o $PP_PATH6

echo "create temporary keychain"
security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

echo "import certificate to keychain"
security import $CERTIFICATE_PATH -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
security list-keychain -d user -s $KEYCHAIN_PATH

echo "apply provisioning profile"
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH1 ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH2 ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH3 ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH4 ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH5 ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH6 ~/Library/MobileDevice/Provisioning\ Profiles
