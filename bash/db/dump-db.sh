#!/usr/bin/env bash
#==============================================================================
# Dump database.
# Saves files into `var/dump/` directory.
# WARNING: all `mysqldumps` calls should be configured with the actual params
#
# Author Igor Okto <web@axisful.info>
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
#       --help|-h                 This help message
#       --none-interactive|-n     [false] Yes to all questions
#
# Examples:
#       Get actual database snapshot:
#           ./scripts/dump-db.sh
#       Dump & compress with timestamp:
#           ./scripts/dump-db.sh --use-gzip --use-datestamp --output /tmp
#
#==============================================================================

BASEDIR=$(dirname "$0")

# Include lib
source "${BASEDIR}"/lib.sh

# Pick up script arguments
_RAW_SQL=true
_USE_GZIP=false
_USE_DATESTAMP=false
_BACKUP_DIR=${CURDIR}/var/dump
_NONINTERACTIVE=false

# Check if all the utils are installed
_EXECUTABLES=(mysqldump gzip)
for bin in "${_EXECUTABLES[@]}"; do
  if [[ -z "$(command -v "${bin}")" ]]; then
    echo "Not found executable for ${bin}"
    exit 1
  fi
done

# Generate name for dump file
function generate_filename() {
  local ext_suffix=$1
  local suffix

  if [[ ${_USE_DATESTAMP} == true ]]; then
    suffix=-$(date +%Y-%m-%d.%H%M%S)
  else
    suffix='-latest'
  fi

  echo "${_BACKUP_DIR}"/database-dump${suffix}.sql"${ext_suffix}"
}

# Script options
for arg in "$@"; do
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
    --none-interactive | -n)
      _NONINTERACTIVE=true
      shift
      ;;
    --help | -h)
      show_help 26
      exit 0
      ;;
  esac
done

# Check if dump dir is exists on current path
if [[ ! -d ${_BACKUP_DIR} ]]; then
  cd ../
fi

if [[ ! -d ${_BACKUP_DIR} ]]; then
  error 'Cannot find dump dir'
  exit 1
fi

# Ask user
if [[ ${_NONINTERACTIVE} == false ]]; then
  while true; do
    read -r -p "Do you wish to dump [dev] database into ${_BACKUP_DIR}? (Y/N) " U_INPUT

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

print 'Start dumping...'

if [[ ${_RAW_SQL} == true ]]; then
  print 'Dump raw sql...'

  filepath=$(generate_filename)
  mysqldump > "${filepath}"

  if [[ $? != 0 ]]; then
    error 'Dump failed'
    exit 1
  fi
elif [[ ${_USE_GZIP} == true ]]; then
  print 'Dump and compress sql...'

  filepath=$(generate_filename '.gz')
  mysqldump | gzip > "${filepath}"

  if [[ $? != 0 ]]; then
    error 'Dump failed'
    exit 1
  fi

else
  error 'Cannot parse script arguments'
  exit 1
fi

_RESULT=$(du -sh "${filepath}")
_VALID=$(echo "${_RESULT}" | grep -E '^0\s' -o)

# Show error if dump is empty
if [[ -n ${_VALID} ]]; then
  error 'Dump failed: file is empty'
  exit 1
fi

print "Dump is done (${filepath})."
echo "${_RESULT}"
