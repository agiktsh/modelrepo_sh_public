#!/bin/bash
# Adds a DatasetMetadata entry to repo/ilidata.xml for each given, already
# validated data file (path relative to repo/), using ilivalidator's
# --createIliData to derive the metadata (title, model link, md5, ...) and
# inserting it with a fresh TID before the closing DataIndex tag.
#
# Usage: add-ilidata-entries.sh <path> [path...]
set -euo pipefail
export LC_ALL=C.UTF-8

if [ "$#" -eq 0 ]; then
  echo "No new data files to index."
  exit 0
fi

nextTid=$(grep -oP '(?<=DatasetMetadata TID=")\d+' repo/ilidata.xml | sort -n | tail -1 || true)
nextTid=$((${nextTid:--1} + 1))

for path in "$@"; do
  echo "$path" > /tmp/ilidata-srcfiles.txt
  java -jar "$ILIVALIDATOR_JAR" --createIliData --ilidata /tmp/ilidata-new-entry.xml --repos repo --srcfiles /tmp/ilidata-srcfiles.txt

  entries=$(grep -oP '<DatasetIdx16\.DataIndex\.DatasetMetadata TID="\d+">.*?</DatasetIdx16\.DataIndex\.DatasetMetadata>' /tmp/ilidata-new-entry.xml)
  if [ -z "$entries" ]; then
    echo "::error::ilivalidator --createIliData produced no ilidata entry for $path"
    exit 1
  fi

  while IFS= read -r entry; do
    entry=$(echo "$entry" | sed -E "s/TID=\"[0-9]+\"/TID=\"$nextTid\"/")
    nextTid=$((nextTid + 1))
    awk -v entry="$entry" '
      /<\/DatasetIdx16\.DataIndex>/ { print entry }
      { print }
    ' repo/ilidata.xml > /tmp/ilidata-merged.xml
    mv /tmp/ilidata-merged.xml repo/ilidata.xml
    echo "Added ilidata.xml entry (TID=$((nextTid - 1))) for $path"
  done <<< "$entries"
done
