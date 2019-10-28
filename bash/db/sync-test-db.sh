#!/usr/bin/env bash
#==============================================================================
# Clone database
#
# Author: Igor Okto <web@axisful.info>
#
# Usage:
#       ./scripts/clone-db.sh OPTIONS
#
# Options will fall back to env variables
# Add these test vars into ~/.profile
#       TEST_WP_DB_HOST=localhost
#       TEST_WP_DB_USER=root
#       TEST_WP_DB_PASS=preved
#       TEST_TARGET_DB_NAME=test_db
#       TEST_SRC_DB_NAME=source_db
#
# Options:
#       --db-user                Database user
#       --db-pass                Database password
#       --db-host                Database hostname [localhost]
#       --src-db-name            Cloned database
#       --target-db-name         Clone to this database
#       --none-interactive|-y    Yes to all questions [false]
#       --help|-h                This help message
#
#==============================================================================

BASEDIR=$(dirname $0)

# Include lib
source ${BASEDIR}/lib.sh

# Pick up script arguments
# If arg is omitted then env var used
TEST_WP_DB_USER="${TEST_WP_DB_USER:-not-set}"
TEST_WP_DB_PASS="${TEST_WP_DB_PASS:-not-set}"
TEST_WP_DB_HOST="${TEST_WP_DB_HOST:-localhost}"
TEST_SRC_DB_NAME="${TEST_SRC_DB_NAME:-not-set}"
TEST_TARGET_DB_NAME="${TEST_TARGET_DB_NAME:-not-set}"
NONINTERACTIVE=false

for arg in "$@"; do
  case ${arg} in
    --db-user)
      TEST_WP_DB_USER="$2"
      shift 2
      ;;
    --db-pass)
      TEST_WP_DB_PASS="$2"
      shift 2
      ;;
    --db-host)
      TEST_WP_DB_HOST="$2"
      shift 2
      ;;
    --src-db-name)
      TEST_SRC_DB_NAME="$2"
      shift 2
      ;;
    --target-db-name)
      TEST_TARGET_DB_NAME="$2"
      shift 2
      ;;
    --none-interactive | -y)
      NONINTERACTIVE=true
      shift
      ;;
    --help | -h)
      show_help 26
      exit 0
      ;;
  esac
done

# Check if all the args are set
ARGS_LIST=$(echo "--db-user ${TEST_WP_DB_USER} --db-pass **** --src-db-name ${TEST_SRC_DB_NAME} --target-db-name ${TEST_TARGET_DB_NAME}")
ARGS=(${TEST_WP_DB_USER} ${TEST_WP_DB_PASS} ${TEST_WP_DB_HOST} ${TEST_SRC_DB_NAME} ${TEST_TARGET_DB_NAME})
for arg in "${ARGS[@]}"; do
  if [[ ${arg} == 'not-set' ]]; then
    error "Not enough arguments: ${ARGS_LIST}"
    exit 1
  fi
done

# Ask user
if [[ ${NONINTERACTIVE} == false ]]; then
  while true; do
    read -r -p "Do you wish to clone database (${TEST_SRC_DB_NAME}) into (${TEST_TARGET_DB_NAME})? (Y/N) " U_INPUT

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

print "Start cloning ${TEST_SRC_DB_NAME}  ➾  ${TEST_TARGET_DB_NAME} ..."

# Start spinner
init_spinner

mysqldump -u ${TEST_WP_DB_USER} --password=${TEST_WP_DB_PASS} ${TEST_SRC_DB_NAME} |
  mysql -u ${TEST_WP_DB_USER} --password=${TEST_WP_DB_PASS} -h ${TEST_WP_DB_HOST} ${TEST_TARGET_DB_NAME}
print 'Done.'

exit 0
