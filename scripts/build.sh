#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${CASHLY_BUILD_ROOT:-$HOME/Library/Developer/CashlyBuild}"
configuration="${1:-Debug}"
xcodebuild -workspace "$project_root/Cashly.xcworkspace" -scheme Production \
  -configuration "$configuration" -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$build_root/$configuration" CODE_SIGNING_ALLOWED=NO build
xcodebuild -workspace "$project_root/Cashly.xcworkspace" -scheme Production \
  -configuration "$configuration" -destination 'generic/platform=macOS' \
  -derivedDataPath "$build_root/macOS-$configuration" CODE_SIGNING_ALLOWED=NO build
xcodebuild -workspace "$project_root/Cashly.xcworkspace" -scheme Production \
  -configuration "$configuration" -destination 'generic/platform=visionOS Simulator' \
  -derivedDataPath "$build_root/visionOS-$configuration" CODE_SIGNING_ALLOWED=NO build
