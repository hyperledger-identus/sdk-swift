#!/bin/bash

# build files
swift build --build-path .build --build-tests > /dev/null 2>&1

# generate momd from xcdatamold to pluto
/Applications/Xcode.app/Contents/Developer/usr/bin/momc \
    ../EdgeAgentSDK/Pluto/Sources/Resources/PrismPluto.xcdatamodeld \
    .build/arm64-apple-macosx/debug/EdgeAgentSDK_Pluto.bundle/PrismPluto.momd > /dev/null 2>&1

swift test --skip-build

# -test-iteration
# xcodebuild -scheme "e2e" -destination "platform=macOS" clean build test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"
