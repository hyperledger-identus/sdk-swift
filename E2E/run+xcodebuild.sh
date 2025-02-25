#!/bin/bash

# xcodebuild -scheme "e2e" \
#     -destination "platform=macOS" \
#     clean \
#     build-for-testing \
#     test-without-building --quiet # > EXECUTION 2>&1

xcodebuild -scheme "e2e" \
    -destination "platform=macOS" \
    build-for-testing \
    test-without-building # > EXECUTION 2>&1

# -skipPackagePluginValidation

# -test-iteration
# xcodebuild -scheme "e2e" -destination "platform=macOS" clean build test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"

