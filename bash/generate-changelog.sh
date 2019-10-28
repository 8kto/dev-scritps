#!/bin/bash
#==============================================================================
# Reads git tags from the current repo and prints out changelog,
# grouping commit messages by tag no.
#==============================================================================

echo "CHANGELOG"
echo ----------------------

# git tag -l --sort=v:refname | sed 's@^[^0-9]\+@@' | sort
git tag -l --sort=v:refname | egrep '^[0-9]' | tac | while read TAG; do
  echo
  if [ ${NEXT} ]; then
    echo [${NEXT}]
  else
    echo "[Current]"
  fi
  GIT_PAGER=cat git log --no-merges --format=" * %s" $TAG..$NEXT
  NEXT=$TAG
done

FIRST=$(git tag -l --sort=v:refname | head -1)
echo
echo [$FIRST]

GIT_PAGER=cat git log --no-merges --format=" * %s" $FIRST
