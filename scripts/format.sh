#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
formatter="$(xcrun --find swift-format)"

case "${1:-}" in
  "")
    arguments=(format --in-place)
    ;;
  --check)
    arguments=(lint --strict)
    ;;
  *)
    echo "Usage: scripts/format.sh [--check]" >&2
    exit 2
    ;;
esac

"$formatter" "${arguments[@]}" \
  --configuration "$project_root/.swift-format" --recursive --parallel \
  "$project_root/Cashly/Cashly" \
  "$project_root/Cashly/CashlyStoreTests" \
  "$project_root/CashlyKit/Sources" \
  "$project_root/CashlyKit/Tests" \
  "$project_root/CashlyKit/Package.swift"
