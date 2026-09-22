#!/bin/bash
# Fails if repository/ilimodels.xml is out of date w.r.t. the .ili files in repository/.
#
# ilimanager --updateIliModels assigns TIDs by filesystem scan order, which is
# not stable across machines, so a raw byte-diff would false-positive on every
# run. We therefore normalize (strip the TID number, sort the records) before
# comparing the checked-in file against a freshly regenerated one.
set -euo pipefail
export LC_ALL=C.UTF-8

canonicalize() {
  grep -oP '<IliRepository20\.RepositoryIndex\.ModelMetadata TID="\d+">.*?</IliRepository20\.RepositoryIndex\.ModelMetadata>' "$1" \
    | sed -E 's/TID="[0-9]+"/TID="X"/' \
    | sort
}

canonicalize repository/ilimodels.xml > /tmp/ilimodels-before.txt

java -jar "$ILIMANAGER_JAR" --updateIliModels --repos repository --out repository/ilimodels.xml

canonicalize repository/ilimodels.xml > /tmp/ilimodels-after.txt

if ! diff -u /tmp/ilimodels-before.txt /tmp/ilimodels-after.txt; then
  git -C repository diff -- ilimodels.xml || true
  git -C repository checkout -- ilimodels.xml
  echo "::error::repository/ilimodels.xml is out of date. Run ilimanager locally (--updateIliModels --repos repository --out repository/ilimodels.xml) and commit the result."
  exit 1
fi

git -C repository checkout -- ilimodels.xml
echo "repository/ilimodels.xml is up to date."
