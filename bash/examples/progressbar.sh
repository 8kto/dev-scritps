#!/usr/bin/env bash
source "$(dirname "$0")"/../lib.sh

function simulate_long_running_process() {
  sleep 3s
}

init_spinner
# OR
# init_progress_bar
simulate_long_running_process
