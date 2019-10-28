#!/usr/bin/env bash
#==============================================================================
# This file contains too specific shell scripts to be included in `lib`,
# but still useful.
#==============================================================================

# Get info for db connection
# @param [string] <format> [DSN|other] Output db info formatted as DSN string or arguments list
function get_db_info() {
  local format_dsn='mysql://%s:%s@%s/%s'
  local format_mysql='-u %s -p%s %s -h %s'
  local formatter

  if [[ "$1" == 'DSN' ]]; then
    formatter="printf('${format_dsn}', \$db['username'], \$db['password'], \$db['host'], \$db['dbname'])"
  else
    formatter="printf('${format_mysql}', \$db['username'], \$db['password'], \$db['dbname'], \$db['host'])"
  fi

  read -r -d '' _EVAL_ << PHPCODE
    \$conf = require '${CURDIR}/var/config/system.php';
    \$db = \$conf['database']['params'];
    ${formatter};
PHPCODE
  php -r "${_EVAL_}"
}

# Prints out a head of file with the doc comment, could be used
# as a help command handler.
#
# @param [number] <amount> lines to be displayed
# @see other shell scripts for usages
# @example:
#     show_help 16 # print first 16 lines of file, drop shell comments
function show_help() {
  head -"$1" "$0" | tail -$(($1 - 2)) | sed -e 's@^#@@g'
}

# Print a version no from the specified file
function get_module_version() {
  grep 'Version:' "$1" | sed 's@\s*Version:\s*\([0-9.]\+\).*$@\1@'
}
