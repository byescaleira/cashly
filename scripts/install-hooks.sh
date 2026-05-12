#!/usr/bin/env bash
#
# install-hooks.sh
#
# Wires the repo-local git hooks under .githooks/ into the active
# clone. Run once after cloning:
#
#   ./scripts/install-hooks.sh
#

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
hooks_dir="$repo_root/.githooks"

if [ ! -d "$hooks_dir" ]; then
  echo "No .githooks directory at $hooks_dir"
  exit 1
fi

git config core.hooksPath "$hooks_dir"
chmod +x "$hooks_dir"/* 2>/dev/null || true

echo "Git hooks now point to $hooks_dir"
