#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${CASHLY_BUILD_ROOT:-$HOME/Library/Developer/CashlyBuild}"
destination="${CASHLY_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=27.0}"
results="$build_root/StoreTests/$(date +%Y%m%d-%H%M%S).xcresult"
action="${CASHLY_STORE_ACTION:-test}"
xcodebuild -workspace "$project_root/Cashly.xcworkspace" -scheme CashlyStoreTests \
  -testPlan StoreKit -destination "$destination" -derivedDataPath "$build_root/StoreTest" \
  -skipPackageUpdates -disableAutomaticPackageResolution -parallel-testing-enabled NO \
  -collect-test-diagnostics never -resultBundlePath "$results" \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO "$@" "$action"
