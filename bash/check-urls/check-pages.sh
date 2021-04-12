#!/usr/bin/env bash
#========================================================================================
# Scripts checks Pages: their HTTP status and also
# runs script check-image-urls.sh over each page to check the images status.
#
# Script checks URL list hardcoded in its own file.
#
# Example:
# > check-pages.sh verbose
#
# Params:
#   $1 Mode: "verbose" for output, any other or empty disables messages (errors only)
#========================================================================================

BASEDIR=$(dirname "$0")
# shellcheck disable=SC2034
INCLUDE_IMAGE_URL_CHECKER=true

# shellcheck source=./check-image-urls.sh
source "$BASEDIR/check-image-urls.sh"

BASE_ABS_URL=http://localhost:8888
PAGES_URLS=(
  "http://localhost:8888/page-1"
  "http://localhost:8888/page-2"
  "http://localhost:8888/page-N"
)

# Open each page URL from $PAGES_URLS
# Check status — assert it is 200
function check_pages() {
  local invalid=0
  local all=0
  local mode=$1

  for url in "${PAGES_URLS[@]}"; do
    if [ "$mode" = "verbose" ]; then
      print "Check status of $url"
    fi

    status_code=$(get_http_status "$url")

    if [ "$status_code" -ne 200 ]; then
      error "Invalid code ($status_code)"
      ((invalid += 1))
    else
      if [ "$mode" = "verbose" ]; then
        print "OK ($status_code)"
      fi
    fi

    ((all += 1))
  done

  echo
  if [ "$mode" = "verbose" ]; then
    print "All pages checked"
    print "Pages: Invalid/All: $invalid/$all"
  fi
}

function check_images_on_pages() {
  for url in "${PAGES_URLS[@]}"; do
    local links
    local mode=$1

    links=$(get_image_urls "$url")

    process_image_urls "$links" "$BASE_ABS_URL" "$mode"
  done
}

# public static void
function main() {
  local mode=$1

  check_pages "$mode"
  check_images_on_pages "$mode"
}

if [ -z "$INCLUDE_PAGE_CHECKER" ]; then
  # shellcheck disable=SC2068
  main $@
fi
