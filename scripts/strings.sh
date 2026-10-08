#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${CASHLY_BUILD_ROOT:-${TMPDIR:-/tmp}/cashly-build}"
objects="$build_root/Debug/Build/Intermediates.noindex/CashlyKit.build/Debug-iphonesimulator"

for catalog in "$project_root"/CashlyKit/Sources/*/Resources/Localizable.xcstrings; do
  target="$(basename "$(dirname "$(dirname "$catalog")")")"
  strings=("$objects/$target-t.build/Objects-normal/arm64/"*.stringsdata)
  if [[ ! -e "${strings[0]}" ]]; then
    echo "No extracted strings for $target. Run scripts/build.sh Debug first." >&2
    exit 1
  fi
  xcrun xcstringstool sync "$catalog" --stringsdata "${strings[@]}"
  echo "$target: $(xcrun xcstringstool print "$catalog" | wc -l | tr -d ' ') strings"
done
