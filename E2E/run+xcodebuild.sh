#!/bin/bash

# xcodebuild -scheme "e2e" \
#     -destination "platform=macOS" \
#     clean \
#     build-for-testing \
#     test-without-building --quiet # > EXECUTION 2>&1

export DEBUG=1
export MEDIATOR_OOB_URL="https://BATATA"
export PRISM_AGENT_URL="https://POTATO"

xcodebuild -scheme "e2e" \
    -destination "platform=macOS" \
    -skipPackagePluginValidation \
    build-for-testing \
    test-without-building \
    DEBUG=1

# xcodebuild -scheme "e2e" -destination "platform=macOS" -skipPackagePluginValidation build-for-testing test-without-building

# -skipPackagePluginValidation

# -test-iteration
# xcodebuild -scheme "e2e" -destination "platform=macOS" clean build test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"

