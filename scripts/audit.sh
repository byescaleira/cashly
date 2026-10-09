#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
swift build -c release --package-path "$project_root/CashlyKit" --product CashlyAudit
"$project_root/CashlyKit/.build/release/CashlyAudit" check
