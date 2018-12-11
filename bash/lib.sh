#!/usr/bin/env bash

export CURDIR=`/bin/pwd`
export BASEDIR=$(dirname $0)

# Print info message
function print {
    echo
    echo -e "\e[38;5;82m>>> $1"
    echo -e "\e[0m"
}

# Print error message
function error {
    echo
    echo -e "\e[31;82m>>> $1"
    echo -e "\e[0m"
}


# Get info for db connection (within docker container)
# param [string] format [DSN|other] Output db info formatted as DSN string or arguments list
function get_db_info {
    local format_dsn='mysql://%s:%s@%s/%s'
    local format_mysql='-u %s -p%s %s -h %s'
    local formatter

    if [[ "$1" = 'DSN' ]] ; then
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

# Show help doc from the caller file header
function show_help {
    head -$1 $0 | tail -$(($1 - 2)) | sed -e 's@^#@@g'
}
