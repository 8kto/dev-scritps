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

# Include lib
source ${BASEDIR}/lib.sh

CURRENT_VER=$(get_module_version my-module-header.php)

# Print a version no from the specified file
function get_module_version() {
  grep 'Version:' "$1" | sed 's@\s*Version:\s*\([0-9.]\+\).*$@\1@'
}

echo "Found version: ${CURRENT_VER}"
echo "Bump '$1' part ..."

bumpversion --current-version "${CURRENT_VER}" "$1" my-module-header.php --allow-dirty

if [[ $? -eq 0 ]]; then
  echo "Version updated to: $(get_module_version my-module-header.php)"
  exit 0
fi
