#!/usr/bin/env bash
#==============================================================================
# Recreate and sync test database with the last actual dump
#
# Script could be run both from the root of the project and within
# scripts directory also.
#
# Script consume parameters set in app/config/parameters.yml
# from within `pimcore_test.db` section.
#
# Author: Igor Okto <web@axisful.info>
#
# Usage:
#       ./scripts/recreate-test-db.sh OPTIONS
#
# Options:
#       --help|-h                 This help message
#       --none-interactive|-n     [false] Yes to all questions
#
#==============================================================================

BASEDIR=$(dirname $0)
DUMP_PATH=${BASEDIR}/../var/dump/database-dump-latest.sql
PARAMETERS_PATH=${BASEDIR}/../app/config/parameters.yml
_NONINTERACTIVE=false

# Include lib
source "${BASEDIR}"/lib.sh

# Script options
for arg in "$@"; do
  case ${arg} in
    --none-interactive | -n)
      _NONINTERACTIVE=true
      shift
      ;;
    --help | -h)
      show_help 19
      exit 0
      ;;
  esac
done

# Check if vendor dir is exists on current path
if [[ ! -d './vendor' ]]; then
  cd ../
fi
if [[ ! -d './vendor' ]]; then
  error 'Cannot find vendor dir'
  exit 1
fi

# Read param from parameters.yml
function get_param() {
  grep "$1" "${PARAMETERS_PATH}" | sed "s@$1\s*:\s*@@;s@'@@g;s/^ *//;s/ *$//"
}

# Charge vars OR set by handle
# (not recommended: don't store any passwords in the script files)
HOST=$(get_param 'pimcore_test.db.host')
PORT=$(get_param 'pimcore_test.db.port')
DBNAME=$(get_param 'pimcore_test.db.dbname')
DBUSER=$(get_param 'pimcore_test.db.user')
DBPASS=$(get_param 'pimcore_test.db.password')

# Check if all vars are set and not empty
VARS=(${HOST} ${PORT} ${DBNAME} ${DBUSER} ${DBPASS})

# Expect exact length
if [[ ${#VARS[@]} != 5 ]]; then
  error "Cannot parse params"
  exit 1
fi

# If any of params is empty
for var in "${VARS[@]}"; do
  if [[ -z "${var}" ]] || [[ "${var}" == '~' ]]; then
    error "Required param is not set"
    exit 1
  fi
done

# Ask user
if [[ ${_NONINTERACTIVE} == false ]]; then
  while true; do
    read -p "Do you wish to recreate the test database (${DBNAME} will be DROPPED)? (Y/N) " U_INPUT

    case ${U_INPUT} in
      [Yy]*)
        break
        ;;
      [Nn]*)
        exit 0
        ;;
      *)
        error "Please answer (y) or (n)."
        ;;
    esac
  done
fi

print "Recreate the test database (${DBNAME})..."
echo "DROP DATABASE IF EXISTS ${DBNAME};" | mysql -u ${DBUSER} -p${DBPASS} -h ${HOST} -P${PORT}
echo "CREATE DATABASE ${DBNAME} COLLATE utf8mb4_general_ci;" | mysql -u ${DBUSER} -p${DBPASS} -h ${HOST} -P${PORT}

print "Restore db structure and data from dump ..."
mysql -u ${DBUSER} -p${DBPASS} -h${HOST} -P${PORT} ${DBNAME} < ${DUMP_PATH}

print "Done."
