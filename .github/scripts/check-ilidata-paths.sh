#!/bin/bash
# Fails if repo/ilidata.xml references a data file that no longer exists.
#
# ilimanager's --updateIliData only supports updating a single dataset entry
# at a time (--datasetId/--data), it has no repository-wide "rescan and
# update" mode like --updateIliModels, so we can't regenerate the whole file
# for a drift check. This is a lighter-weight referential-integrity check
# instead: every <path> entry must point at a file that actually exists.
set -euo pipefail
export LC_ALL=C.UTF-8

missing=0
while IFS= read -r path; do
  if [ ! -f "repo/$path" ]; then
    echo "::error::repo/ilidata.xml references missing file: $path"
    missing=1
  fi
done < <(grep -oP '(?<=<path>)[^<]+' repo/ilidata.xml)

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "All paths referenced in repo/ilidata.xml exist."
