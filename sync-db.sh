#!/usr/bin/env bash
#==============================================================================
# Sync dev database with the last actual dump
#
# Script could be run both from the root of the project and within
# scripts directory also.
#
# Author: Igor Ivlev <ivlev@kurzor.net>
#
#==============================================================================

BASEDIR=$(dirname $0)

# Include lib
source ${BASEDIR}/lib.sh

# Check if vendor dir is exists on current path
if [ ! -d './vendor' ]; then
    cd ../
fi
if [ ! -d './vendor' ]; then
    error 'Cannot find vendor dir'
    exit 1
fi

if [ ! -f './var/dump/database-dump-latest.sql' ]; then
    error 'Cannot find dump'
    exit 1
fi

# Ask user
while true ; do
    read -p "Do you wish to sync dev database with the last actual dump? (Y/N) " U_INPUT

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

print "Upload sql dump into dev database..."
mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -h${MYSQL_HOST} ${MYSQL_DATABASE} < var/dump/database-dump-latest.sql
print "Done"

exit 0
