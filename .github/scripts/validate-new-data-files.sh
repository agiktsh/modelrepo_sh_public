#!/bin/bash
# Validates each given data file (path relative to repo/) with ilivalidator
# against its associated model. Validates all of them and fails if any one
# of them is invalid.
#
# Usage: validate-new-data-files.sh <path> [path...]
set -euo pipefail
export LC_ALL=C.UTF-8

if [ "$#" -eq 0 ]; then
  echo "No new data files to validate."
  exit 0
fi

status=0
for path in "$@"; do
  echo "::group::ilivalidator $path"
  if ! java -jar "$ILIVALIDATOR_JAR" --modeldir "repo;%ILI_DIR;http://models.interlis.ch/;%JAR_DIR" "repo/$path"; then
    echo "::endgroup::"
    echo "::error::repo/$path failed ilivalidator validation."
    status=1
  else
    echo "::endgroup::"
  fi
done

exit "$status"
