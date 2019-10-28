#!/usr/bin/env bash
#==============================================================================
# Shared utils
#==============================================================================

export CURDIR=$(/bin/pwd)
export BASEDIR=$(dirname "$0")

# Print info message
function print() {
  echo
  echo -e "\e[38;5;82m>>> $1"
  echo -e "\e[0m"
}

# Print error message
function error() {
  echo
  echo -e "\e[31;82m>>> $1"
  echo -e "\e[0m"
}

# Progress bars
#==============================================================================
function progress_spinner() {
  spinner='|/—\|/—\'

  while :; do
    for i in $(seq 0 3); do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep .5s
    done
  done
}

# Progress bar with dots
function progress_bar() {
  while :; do
    for i in $(seq 0 3); do
      echo -n ". "
      echo -en "\010"
      sleep .5s
    done
  done
}

# Kill the process by PID on any signal, including script exit
function catch_process() {
  trap "kill -9 ${1}" $(seq 0 15)
}

function init_spinner() {
  progress_spinner &
  catch_process $!
}

function init_progress_bar() {
  progress_bar &
  catch_process $!
}
