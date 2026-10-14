#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${CASHLY_BUILD_ROOT:-$HOME/Library/Developer/CashlyBuild}"
destination="${CASHLY_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=27.0}"
xcodebuild -workspace "$project_root/Cashly.xcworkspace" -scheme CashlyKitTests \
  -destination "$destination" -derivedDataPath "$build_root/Test" \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO test
