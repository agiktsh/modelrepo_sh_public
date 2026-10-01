#!/bin/bash
# Updates repository/ilidata.xml for each given, already validated MODIFIED
# (not new) data file (path relative to repository/). Uses ilivalidator's
# --updateIliData, which appends a new dataset-version entry chained to the
# existing one via <precursorVersion> - it does not edit the old entry in
# place, matching INTERLIS' dataset versioning model.
#
# Usage: update-ilidata-entries.sh <path> [path...]
set -euo pipefail
export LC_ALL=C.UTF-8

if [ "$#" -eq 0 ]; then
  echo "No modified data files to update."
  exit 0
fi

# Finds the <id> of the DatasetMetadata entry whose <files> reference the
# given path. Block-based (not line-based): the checked-in ilidata.xml is
# pretty-printed across multiple lines, unlike the single-line entries our
# own tooling generates.
findDatasetId() {
  PATH_TO_FIND="$1" perl -0777 -ne '
    my $target = $ENV{PATH_TO_FIND};
    while (/<DatasetIdx16\.DataIndex\.DatasetMetadata\b.*?<\/DatasetIdx16\.DataIndex\.DatasetMetadata>/sg) {
      my $block = $&;
      if (index($block, "<path>$target</path>") >= 0) {
        if ($block =~ /<id>([^<]+)<\/id>/) { print "$1"; last; }
      }
    }
  ' repository/ilidata.xml
}

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for path in "$@"; do
  datasetId=$(findDatasetId "$path")
  if [ -z "$datasetId" ]; then
    # File predates our ilidata.xml automation and was never indexed (several
    # of our own catalogues are in this state) - treat it like a new file
    # rather than failing the PR for a pre-existing gap.
    echo "No existing ilidata.xml entry for repository/$path - adding it as new instead."
    "$scriptDir/add-ilidata-entries.sh" "$path"
    continue
  fi

  java -jar "$ILIVALIDATOR_JAR" --updateIliData --ilidata /tmp/ilidata-updated.xml --repos repository --datasetId "$datasetId" "repository/$path"
  cp /tmp/ilidata-updated.xml repository/ilidata.xml
  echo "Updated ilidata.xml entry for dataset '$datasetId' (repository/$path)"
done
