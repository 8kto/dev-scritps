#!/usr/bin/env bash
#==============================================================================
# Dump database. Script should be launched only within Docker container as it
# contains actual project database.
# Saves files into `var/dump/` directory.
#
# Author: Igor Ivlev <ivlev@kurzor.net>
#
# Usage:
#       ./scripts/dump-db.sh OPTIONS
#
# Options:
#       --raw-sql        [true]   Dump raw sql file
#       --use-gzip       [false]  Compress dump file with gzip
#       --use-datestamp  [false]  Add datestamp into filename.
#                                 If false, creates `database-dump-latest.sql`
#       --output         [true]   Output directory
#
# Examples:
#       Get actual database snapshot:
#           ./scripts/dump-db.sh
#       Dump & compress with timestamp:
#           ./scripts/dump-db.sh --use-gzip --use-datestamp --output /tmp/
#
#==============================================================================

CURDIR=`/bin/pwd`
BASEDIR=$(dirname $0)

# Pick up script arguments
_RAW_SQL=true
_USE_GZIP=false
_USE_DATESTAMP=false
_BACKUP_DIR=${CURDIR}/var/dump

# Include lib
source ${BASEDIR}/lib.sh

# Check if dump dir is exists on current path
if [ ! -d ${_BACKUP_DIR} ]; then
    cd ../
fi

if [ ! -d ${_BACKUP_DIR} ]; then
    error 'Cannot find dump dir'
    exit 1
fi

# Check if all the utils are installed
_EXECUTABLES=( mysqldump gzip )
for bin in "${_EXECUTABLES[@]}" ; do
	if [[ -z "$(which ${bin})" ]] ; then
	    error "Not found executable for ${bin}"
	    exit 1
	fi
done

# Generate name for dump file
function generate_filename {
    local ext_suffix=$1
    local suffix

    if [[ ${_USE_DATESTAMP} = true ]] ; then
        suffix=-$(date +%Y-%m-%d.%H%M%S)
    else
        suffix='-latest'
    fi

    result=${_BACKUP_DIR}/database-dump${suffix}.sql${ext_suffix}
    echo ${result}
}

# Script options
for arg in "$@" ; do
    case ${arg} in
        --raw-sql)
            _RAW_SQL=true
            _USE_GZIP=false
            shift
        ;;
        --use-gzip)
            _RAW_SQL=false
            _USE_GZIP=true
            shift
        ;;
        --use-datestamp)
            _USE_DATESTAMP=true
            shift
        ;;
        --output)
            _BACKUP_DIR=$2
            shift 2
        ;;
        --help|-h)
            show_help 24
            exit 0
        ;;
    esac
done

# Ask user
while true ; do
    read -p "Do you wish to dump [dev] database? (Y/N) " U_INPUT

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

print 'Start dumping...'

# Clear caches, logs, non-needed data objects +
# internal Pimcore maintenance jobs
print "Clear non-needed stuff..."
./bin/console pimcore:email:cleanup --older-than-days 0
./bin/console cache:clear
./bin/console pimcore:cache:clear
./bin/console pipopr:submissions:clear
./bin/console pimcore:maintenance -f -v

if [[ ${_RAW_SQL} = true ]] ; then
    print 'Dump raw sql...'

    filepath=$(generate_filename)
    mysqldump $(get_db_info 'mysqldump') > ${filepath}

    if [[ $? != 0 ]] ; then
        error 'Dump failed: had been launched within Docker?'
        exit 1
    fi
elif [[ ${_USE_GZIP} = true ]] ; then
    print 'Dump and compress sql...'

    filepath=$(generate_filename '.gz')
    mysqldump $(get_db_info) | gzip > ${filepath}

    if [[ $? != 0 ]]; then
        error 'Dump failed: had been launched within Docker?'
        exit 1
    fi

else
    error 'Cannot parse script arguments'
    exit 1
fi

_RESULT=$(du -sh ${filepath})
_VALID=$(echo "${_RESULT}" | egrep '0 ' -o)

# Show error if dump is empty
if [[ ! -z ${_VALID} ]] ; then
    error 'Dump failed: file is empty'
    exit 1
fi

print 'Dump is done.'
echo ${_RESULT}
exit 0
