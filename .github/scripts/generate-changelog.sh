#!/bin/bash
# Prints a simple markdown changelog of what changed under repository/ since
# the previous GitHub release, based on file status (added/modified/deleted/
# renamed), not commit messages - the model repository's file tree is what
# release consumers actually care about.
set -uo pipefail
export LC_ALL=C.UTF-8

prevTag=$(gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null)

if [ -z "$prevTag" ]; then
  echo "## Changelog"
  echo
  echo "Initial release - no previous release to compare against."
  exit 0
fi

echo "## Changelog"
echo
echo "Changes under \`repository/\` since [$prevTag](https://github.com/${GITHUB_REPOSITORY}/releases/tag/$prevTag):"
echo

diffOutput=$(git diff --name-status -M "$prevTag" HEAD -- repository/)

if [ -z "$diffOutput" ]; then
  echo "No changes."
  exit 0
fi

printSection() {
  local heading="$1"
  local statusPrefix="$2"
  local lines
  lines=$(echo "$diffOutput" | awk -v p="$statusPrefix" '$1 ~ "^"p {out=""; for(i=2;i<=NF;i++){gsub(/^repository\//, "", $i); out = out (i>2?" -> ":"") $i}; print out}')
  if [ -n "$lines" ]; then
    echo "### $heading"
    echo
    while IFS= read -r path; do
      [ -z "$path" ] && continue
      echo "- \`${path}\`"
    done <<< "$lines"
    echo
  fi
}

printSection "Added" "A"
printSection "Modified" "M"
printSection "Deleted" "D"
printSection "Renamed" "R"
