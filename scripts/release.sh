#!/usr/bin/env bash
#
# release.sh
#
# Cuts a semver tag + GitHub release for the current HEAD. Pulls the
# changelog from commits since the previous tag (Conventional Commits
# style), runs the macOS test guardrail, then `gh release create`.
#
# Usage:
#   ./scripts/release.sh patch          # bump z
#   ./scripts/release.sh minor          # bump y, reset z
#   ./scripts/release.sh major          # bump x, reset y.z
#   ./scripts/release.sh 1.2.3          # explicit version
#   ./scripts/release.sh --dry-run minor  # preview without tagging
#
# Requires:
#   - gh CLI authenticated (gh auth status)
#   - clean working tree
#   - swift toolchain
#

set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 [--dry-run] {major|minor|patch|x.y.z}

  major       Bump major, reset minor + patch
  minor       Bump minor, reset patch
  patch       Bump patch
  x.y.z       Use an explicit semver string

  --dry-run   Print the tag + changelog without creating anything
EOF
    exit 1
}

dry_run=0
bump=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=1 ;;
        major|minor|patch|[0-9]*.[0-9]*.[0-9]*) bump="$arg" ;;
        *) usage ;;
    esac
done

if [ -z "$bump" ]; then
    usage
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# Guard: clean tree
if [ -n "$(git status --porcelain)" ]; then
    echo "release: working tree dirty, commit or stash first."
    exit 1
fi

# Guard: must be on main
branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != "main" ]; then
    echo "release: not on main (current: $branch)."
    exit 1
fi

# Resolve previous tag + next version
prev_tag=$(git tag --sort=-v:refname | head -1 || true)
if [ -z "$prev_tag" ]; then
    prev_tag="" # first release
    prev_version="0.0.0"
else
    prev_version="${prev_tag#v}"
fi

if [[ "$bump" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    next_version="$bump"
else
    IFS='.' read -r maj min pat <<< "$prev_version"
    case "$bump" in
        major) next_version="$((maj + 1)).0.0" ;;
        minor) next_version="${maj}.$((min + 1)).0" ;;
        patch) next_version="${maj}.${min}.$((pat + 1))" ;;
    esac
fi

next_tag="v$next_version"

# Changelog from commits since prev_tag
if [ -n "$prev_tag" ]; then
    range="$prev_tag..HEAD"
else
    range="HEAD"
fi

changelog=$(git log "$range" --pretty=format:"- %s" --no-merges)

if [ -z "$changelog" ]; then
    echo "release: no commits since $prev_tag."
    exit 1
fi

echo "Previous: ${prev_tag:-(none)}"
echo "Next:     $next_tag"
echo
echo "Changelog:"
echo "$changelog"
echo

if [ "$dry_run" -eq 1 ]; then
    echo "(dry-run — no tag created)"
    exit 0
fi

# Guardrail: swift build + test must pass
echo "release: running guardrail (swift build + swift test)"
( cd CashlyKit && swift build > /dev/null )
( cd CashlyKit && swift test --parallel > /dev/null )

# Create tag + release
git tag -a "$next_tag" -m "Release $next_tag"
git push origin "$next_tag"

gh release create "$next_tag" \
    --title "$next_tag" \
    --notes "$changelog"

echo "release: $next_tag created."
