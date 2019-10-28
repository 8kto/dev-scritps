#!/usr/bin/env bash
#==============================================================================
# Sync dev database with the last actual dump
#
# Script could be run both from the root of the project and within
# scripts directory also.
#
# Author: Igor Okto <web@axisful.info>
#
# Usage:
#       ./scripts/sync-db.sh OPTIONS
#
# Options:
#       --help|-h                 This help message
#       --none-interactive|-n     [false] Yes to all questions
#
#==============================================================================

BASEDIR=$(dirname $0)
_NONINTERACTIVE=false

# Include lib
source ${BASEDIR}/lib.sh

# Script options
for arg in "$@" ; do
    case ${arg} in
        --none-interactive|-n)
            _NONINTERACTIVE=true
            shift
        ;;
        --help|-h)
            show_help 16
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

if [[ ! -f './var/dump/database-dump-latest.sql' ]]; then
    error 'Cannot find dump'
    exit 1
fi

# Ask user
if [[ ${_NONINTERACTIVE} = false ]] ; then
    while true ; do
        read -p "Do you wish to sync the dev database (${MYSQL_DATABASE}) with the last actual dump? (Y/N) " U_INPUT

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

print "Upload sql dump into dev database (${MYSQL_DATABASE})..."
mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -h${MYSQL_HOST} ${MYSQL_DATABASE} < var/dump/database-dump-latest.sql
print "Done"

exit 0
