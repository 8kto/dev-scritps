#!/usr/bin/env bash
#==============================================================================
# Updates version in specified file.
# Script decorates `bumpversion`, it has the same `major|minor|patch` argument
# with the same meaning (without param name).
#
# bumpversion should be installed: https://pypi.org/project/bumpversion/
#==============================================================================

if [[ -z "$1" ]]; then
  echo "Provide a semver part to bump: major.minor.patch"
  exit 1
fi

BASEDIR=$(dirname $0)
# VERSION_FILE=examples/package.json
VERSION_FILE=$1

# Include lib
source ${BASEDIR}/lib.sh

# Print a version no from the specified file
function get_module_version() {
  grep -Ei '\"?Version\"?\s*:' "$1" | sed 's@\s*\"?Version\"?:\s*\"?\([0-9.]\+\).*$@\1@I'
}

# Modify this call to add more files which contain version:
CURRENT_VER=$(get_module_version $VERSION_FILE) 

echo "Found version: ${CURRENT_VER}"
echo "Bump '$2' part ..."

bumpversion --current-version "${CURRENT_VER}" "$2" $VERSION_FILE --allow-dirty

if [[ $? -eq 0 ]]; then
  echo "Version updated to: $(get_module_version $VERSION_FILE)"
  exit 0
fi
