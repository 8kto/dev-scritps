#!/usr/bin/env bash
#==============================================================================
# Dump database routines: views, procedures etc.
#
# Author: Igor Okto <web@axisful.info>
#
# Usage:
#       ./scripts/dump-db-routine.sh OPTIONS
#
# Options will fall back to env variables
# Add these test vars into ~/.profile
#       TEST_AC_WP_DB_HOST=localhost
#       TEST_AC_WP_DB_USER=root
#       TEST_AC_WP_DB_PASS=preved
#       TEST_AC_TARGET_DB_NAME=wordpress_test
#       TEST_AC_SRC_DB_NAME=alpinewp
#
# Options (if arg is omitted then env var used):
#       --db-user       Database user
#       --db-pass       Database password
#       --db-host       Database hostname [localhost]
#       --db-name       Database name
#       --output-dir    Save output in this dir
#       --help|-h       This help message
#
#==============================================================================
# TODO REMOVE script
BASEDIR=$(dirname $0)

# Include lib
source ${BASEDIR}/lib.sh

# Pick up script arguments
TEST_AC_WP_DB_USER="${TEST_AC_WP_DB_USER:-not-set}"
TEST_AC_WP_DB_PASS="${TEST_AC_WP_DB_PASS:-not-set}"
TEST_AC_WP_DB_HOST="${TEST_AC_WP_DB_HOST:-localhost}"
TEST_AC_DB_NAME="${TEST_AC_SRC_DB_NAME:-not-set}"
OUTPUT_DIR="/tmp"
FORMATTER=./vendor/bin/sql-formatter

for arg in "$@" ; do
    case ${arg} in
        --db-user)
            TEST_AC_WP_DB_USER="$2"
            shift 2
        ;;
        --db-pass)
            TEST_AC_WP_DB_PASS="$2"
            shift 2
        ;;
        --db-host)
            TEST_AC_WP_DB_HOST="$2"
            shift 2
        ;;
        --db-name)
            TEST_AC_DB_NAME="$2"
            shift 2
        ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
        ;;
        --help|-h)
            show_help 25
            exit 0
        ;;
    esac
done


# Check if all the args are set
ARGS_LIST=$(echo "--db-user ${TEST_AC_WP_DB_USER} --db-pass **** --db-name ${TEST_AC_DB_NAME} ")
ARGS=( ${TEST_AC_WP_DB_USER} ${TEST_AC_WP_DB_PASS} ${TEST_AC_WP_DB_HOST} ${TEST_AC_DB_NAME} )
for arg in "${ARGS[@]}" ; do
	if [[ ${arg} == 'not-set' ]] ; then
	    error "Not enough arguments: ${ARGS_LIST}"
	    exit 1
	fi
done

MODULE_VER=$(grep 'Version:' alpinecamp.php | sed 's@\s*Version: \([0-9.]\+\).*$@\1@')
GIT_REV=$(git rev-list HEAD --count)
FILEPATH="${OUTPUT_DIR}/routine-v${MODULE_VER}-r${GIT_REV}.sql"

DELIMITER="/*----------------------------------------------------------------------*/"
BR="/*BR*/"
BR_E="/\*BR\*/"
VIEWS_NO=0
VIEWS_SFX="-- Views amount:"

print "Dump routine for [${TEST_AC_DB_NAME}]  ➾  ${FILEPATH} ..."

# Start spinner
progress_spinner &
# Make a note of its Process ID (PID):
SPIN_PID=$!
# Kill the spinner on any signal, including our own exit.
trap "kill -9 ${SPIN_PID}" `seq 0 15`

echo "-- Dump for Alpinecamp v${MODULE_VER}-r${GIT_REV}" > ${FILEPATH}
echo "-- Created at $(date)" >> ${FILEPATH}
echo ${VIEWS_SFX} >> ${FILEPATH}

# Format SQL, fix cyrillic aliases
function custom_format {
    ${FORMATTER} $@ | sed "s@\[Не найдено\]@'[Не найдено]'@g"
}

# Dump only views
mysql \
    -u ${TEST_AC_WP_DB_USER} \
    --password=${TEST_AC_WP_DB_PASS} \
    ${TEST_AC_DB_NAME} \
    --skip-column-names \
    --batch \
    --execute \
        "SELECT \
        CONCAT('CREATE OR REPLACE VIEW ', TABLE_NAME, ' AS ', VIEW_DEFINITION, ';') \
        FROM INFORMATION_SCHEMA.VIEWS \
        WHERE TABLE_SCHEMA = '${TEST_AC_DB_NAME}'" |
    xargs -I % \
    echo "${BR}%" |
    custom_format |
    sed "s@${BR_E}@\n\n${DELIMITER}@g" >> \
    ${FILEPATH}

VIEWS_NO=$(egrep 'VIEW.+AS' ${FILEPATH} | wc -l)
sed -i "s/${VIEWS_SFX}/${VIEWS_SFX} ${VIEWS_NO}/" ${FILEPATH}

print 'Done.'
exit 0
