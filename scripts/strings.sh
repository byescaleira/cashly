#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${CASHLY_BUILD_ROOT:-${TMPDIR:-/tmp}/cashly-build}"
objects="$build_root/Debug/Build/Intermediates.noindex"
catalog="$project_root/Cashly/Cashly/Localizable.xcstrings"

strings=()
while IFS= read -r -d '' file; do
  strings+=("$file")
done < <(find "$objects" -path '*Debug-iphonesimulator*' -name '*.stringsdata' \
  -not -path '*/CashlyAudit*' -not -path '*/CashlyMock*' -not -path '*/CashlyPreview*' \
  -not -path '*/CashlyMCP-t.build/*' -not -path '*Tests*' -print0)

if [[ ${#strings[@]} -eq 0 ]]; then
  echo "No extracted strings in $objects. Run scripts/build.sh Debug first." >&2
  exit 1
fi
xcrun xcstringstool sync "$catalog" --stringsdata "${strings[@]}"
echo "Localizable: $(xcrun xcstringstool print "$catalog" | wc -l | tr -d ' ') strings"
