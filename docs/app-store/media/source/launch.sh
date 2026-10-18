#!/bin/bash
set -euo pipefail
device="${1:?usage: launch.sh <simulator udid> [fresh] [extra launch arguments...]}"
shift
build_root="${CASHLY_BUILD_ROOT:-$HOME/Library/Developer/CashlyBuild-media}"
app="$build_root/Debug/Build/Products/Debug-iphonesimulator/Cashly.app"
bundle=com.byescaleira.cashly
if [ "${1:-}" = fresh ]; then
  shift
  xcrun simctl uninstall "$device" "$bundle" 2>/dev/null || true
  xcrun simctl install "$device" "$app"
fi
xcrun simctl status_bar "$device" override --time 9:41 --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl ui "$device" appearance "${CASHLY_APPEARANCE:-light}"
xcrun simctl terminate "$device" "$bundle" 2>/dev/null || true
xcrun simctl launch "$device" "$bundle" \
  -cashly.developer.showcase YES \
  -cashly.settings.currency USD \
  -cashly.developer.store.plan "${CASHLY_PLAN:-pro}" \
  -cashly.user.id f47ac10b-58cc-4372-a567-0e02b2c3d479 \
  -cashly.home.shopSpotlight.hidden "$(date +%Y%m)" \
  -AppleLanguages "(en)" -AppleLocale en_US "$@"
