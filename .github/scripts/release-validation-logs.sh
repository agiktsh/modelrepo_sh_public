#!/bin/bash
# Re-validates the repository/ content at release time and writes the raw
# tool output of ili2c, ilimanager and ilivalidator to /tmp/release-logs/, so
# they can be attached to the GitHub release as evidence. Fails (non-zero
# exit) if any of the three checks is not clean - the release step should
# then not publish.
#
# ili2c and ilivalidator write their native --log (more accurate than their
# console output - e.g. console mislabels some Warnings as Info, and can
# corrupt non-ASCII characters). ilimanager 0.9.1's --log silently produces
# no file at all, so that one falls back to capturing console output.
set -uo pipefail
export LC_ALL=C.UTF-8

logdir=/tmp/release-logs
mkdir -p "$logdir"
status=0

echo "=== ili2c --check-repo-ilis ==="
java -jar "$ILI2C_JAR" --log "$logdir/ili2c.log" --check-repo-ilis repository
if [ "$?" -ne 0 ]; then
  status=1
fi

echo "=== ilimanager --updateIliModels (dry run, no commit) ==="
scratch=/tmp/release-ilimanager-check
rm -rf "$scratch"
cp -r repository "$scratch"
java -jar "$ILIMANAGER_JAR" --updateIliModels --repos "$scratch" --out "$scratch/ilimodels.xml" 2>&1 | tee "$logdir/ilimanager.log"
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  status=1
fi

canonicalize() {
  grep -oP '<IliRepository20\.RepositoryIndex\.ModelMetadata TID="\d+">.*?</IliRepository20\.RepositoryIndex\.ModelMetadata>' "$1" \
    | sed -E 's/TID="[0-9]+"/TID="X"/' \
    | sort
}
if diff -u <(canonicalize repository/ilimodels.xml) <(canonicalize "$scratch/ilimodels.xml") >> "$logdir/ilimanager.log"; then
  echo "repository/ilimodels.xml is up to date." | tee -a "$logdir/ilimanager.log"
else
  echo "::error::repository/ilimodels.xml is out of date." | tee -a "$logdir/ilimanager.log"
  status=1
fi

echo "=== ilivalidator (all data files) ==="
# ilivalidator's --log truncates on each run rather than appending, so each
# file gets its own temp log which we then concatenate ourselves.
: > "$logdir/ilivalidator.log"
files=$(find repository -name '*.xml' | grep -vE '/(ilidata|ilimodels|ilisite)\.xml$' | sed 's#^repository/##')
if [ -n "$files" ]; then
  while IFS= read -r f; do
    echo "::group::ilivalidator $f"
    java -jar "$ILIVALIDATOR_JAR" --modeldir "repository;%ILI_DIR;http://models.interlis.ch/;%JAR_DIR" --log /tmp/ilivalidator-file.log "repository/$f"
    fileStatus=$?
    {
      echo "### $f ###"
      cat /tmp/ilivalidator-file.log
      echo
    } >> "$logdir/ilivalidator.log"
    if [ "$fileStatus" -ne 0 ]; then
      echo "::endgroup::"
      echo "::error::repository/$f failed ilivalidator validation."
      status=1
    else
      echo "::endgroup::"
    fi
  done <<< "$files"
else
  echo "No data files to validate." > "$logdir/ilivalidator.log"
fi

exit "$status"
