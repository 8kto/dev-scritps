#!/usr/bin/env bash
#==============================================================================
# Run linters and tests for project, including:
#   * Syntax check with parallel-lint and native Symfony tools
#   * Static analysis with phpstan and psalm
#   * Tests for Codeception
#
# Script could be run both from the root of the project and within
# scripts directory also.
#
# Author: Igor Ivlev <ivlev@kurzor.net>
#
# Usage:
#       ./scripts/run-test.sh OPTIONS
#
# Options:
#       --skip-syntax-check       [false]   Skip syntax checks
#       --skip-phpstan            [false]   Skip phpstan checks
#       --skip-psalm              [false]   Skip psalm checks
#       --skip-codeception        [false]   Skip Codeception tests
#       --extra-codeception-args  [none]    Extra args for conception
#       --help|-h                           This help message
#
# Examples:
#       Run all the tests and linters/SA:
#           ./scripts/run-test.sh
#       Run all the tests and linters/SA with verbose codecept output:
#           ./scripts/run-test.sh --extra-codeception-args --steps
#       Run only linters/SA:
#           ./scripts/run-test.sh --skip-codeception
#       Run only Codeception tests:
#           ./scripts/run-test.sh --skip-phpstan --skip-psalm --skip-syntax-check
#
#==============================================================================

BASEDIR=$(dirname $0)

# Include lib
source ${BASEDIR}/lib.sh

# Pick up script arguments
SKIP_CODECEPT=false
SKIP_SYNTAX_CHECK=false
SKIP_PHPSTAN=false
SKIP_PSALM=false
EXTRA_CODECEPT_ARGS='--'

for arg in "$@" ; do
    case ${arg} in
        --skip-codeception)
            SKIP_CODECEPT=true
            shift
        ;;
        --skip-syntax-check)
            SKIP_SYNTAX_CHECK=true
            shift
        ;;
        --skip-phpstan)
            SKIP_PHPSTAN=true
            shift
        ;;
        --skip-psalm)
            SKIP_PSALM=true
            shift
        ;;
        --extra-codeception-args)
            EXTRA_CODECEPT_ARGS="$2"
            shift 2
        ;;
        --help|-h)
            show_help 23
            exit 0
        ;;
    esac
done

print 'Tests starts...'

# Check if vendor dir is exists on current path
if [ ! -d './vendor' ]; then
    cd ../
fi
if [ ! -d './vendor' ]; then error 'Cannot find vendor dir'; exit 1; fi

if [[ ${SKIP_SYNTAX_CHECK} = false ]]; then
    print 'Syntax errors check...'
    php vendor/bin/parallel-lint --colors --exclude app --exclude vendor src app/Resources

    if [[ $? != 0 ]]; then
        error 'Tests failed: Syntax errors found'
        exit 1
    fi

    print 'Lint with Symfony tools...'
    ./bin/console lint:twig app/Resources/
    ./bin/console lint:yaml app/
    ./bin/console lint:yaml src/
fi

if [[ ${SKIP_PSALM} = false ||  ${SKIP_PHPSTAN} = false ]]; then
    print 'Static analysis...'
fi

if [[ ${SKIP_PHPSTAN} = false ]]; then
    print 'Running phpstan...'
    php vendor/bin/phpstan analyse --ansi --level max -c phpstan.neon src/

    if [[ $? != 0 ]]; then
        error 'Tests failed: phpstan errors found'
        exit 1
    fi
fi

if [[ ${SKIP_PSALM} = false ]]; then
    print 'Running psalm...'
    php vendor/bin/psalm --show-info=false

    if [[ $? != 0 ]]; then
        error 'Tests failed: psalm errors found'
        exit 1
    fi
fi

if [[ ${SKIP_CODECEPT} != true ]]; then
    print 'Codeception tests...'

    export SYMFONY_DEPRECATIONS_HELPER=weak
    vendor/bin/codecept ${EXTRA_CODECEPT_ARGS} run

    if [[ $? != 0 ]]; then
        error 'Codeception tests failed'
        exit 1
    fi
fi

print 'Tests successfully ended'
exit 0
