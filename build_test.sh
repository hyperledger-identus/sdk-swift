#!/bin/bash

set -e

DERIVED_DATA_DIR="$HOME/.derivedData"
DESTINATION="platform=macOS,name=My Mac"
SCHEME="EdgeAgentSDK-Package"
LCOV_DIR="$DERIVED_DATA_DIR/lcov"

echo "Derived data directory: $DERIVED_DATA_DIR"
echo "lcov partials directory: $LCOV_DIR"

# Clean derived data dir
echo "Cleaning derived data directory"
rm -rf "$DERIVED_DATA_DIR"
mkdir "$DERIVED_DATA_DIR"

# Clean lcov dir
echo "Cleaning lcov partials directory"
rm -rf "$LCOV_DIR"
mkdir "$LCOV_DIR"

set -euo pipefail

# Run build and test
echo "Running build and test"
xcodebuild -scheme "EdgeAgentSDK-Package" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    -enableCodeCoverage YES \
    clean build test | xcpretty
echo "Execution completed"
echo "Execution completed"

# lcov generation
PROF_DATA=$(find "$DERIVED_DATA_DIR" -name "Coverage.profdata" | head -n 1)
if [ -z "$PROF_DATA" ]; then
    echo "Error: Coverage.profdata not found. Ensure 'enableCodeCoverage' is YES."
    exit 1
fi
echo "Profdata found: $PROF_DATA"

BINARIES=$(find "$DERIVED_DATA_DIR" -type f -name "*Tests" ! -name "*.xctest")
for BINARY in $BINARIES; do
  BASE_NAME=$(basename "$BINARY")
  echo "Generating coverage for $BASE_NAME"
  LCOV_NAME="${BASE_NAME}.lcov"
  
  xcrun llvm-cov export \
    --format=lcov \
    --instr-profile "$PROF_DATA" \
    "$BINARY" \
    --ignore-filename-regex="Tests/|.*\.(xcodeproj|xctest).*|.*/.derivedData/.*|.*/SourcePackages/.*" \
    > "$LCOV_DIR/$LCOV_NAME"
done

echo "Merging partials to lcov.info"
cat "$LCOV_DIR"/*.lcov > lcov.info
