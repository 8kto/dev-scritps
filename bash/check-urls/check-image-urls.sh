#!/usr/bin/env bash
#========================================================================================
# Scripts checks image URLs (any tags with attributes href, src, content (meta)):
# opens URL, expects the response is 200 OK
#
# Example:
# > check-image-urls.sh http://localhost:8888/com-qs/de/cms/homepage http://localhost:8888 verbose
#
# Params:
#   $1 Page URL
#   $2 Absolute URL — a base that will be applied to the relative URLs
#   $3 Mode: "verbose" for output, any other or empty disables messages (errors only)
#========================================================================================

# Print info message ($1)
function print() {
  echo -e "\e[38;5;82m> $1 \e[0m"
}

# Print error message ($1)
function error() {
  echo -e "\e[31;82m> $1 \e[0m"
}

# Get all image URLs from the provided URL ($1)
function get_image_urls() {
  wget -q "$1" -O - |
    grep -o -E '(?:href|src|content)="([^"#]+\.(svg|png|jpe?g|webp|gif))"' |
    cut -d'"' -f2
}

function get_http_status() {
  curl -s -o /dev/null -w "%{http_code}" "$1"
}

# Check status of every URL in passed list ($1)
# If URL is not absolute, apply an absolute base ($2)
function process_image_urls() {
  local RE_ABSOLUTE_URL="^https?:\/\/"

  local urls=$1
  local base_url=$2
  local mode=$3

  local invalid=0
  local all=0

  for url in $urls; do
    abs_url=$url

    if [[ ! $url =~ $RE_ABSOLUTE_URL ]]; then
      normalized_path=$(echo "$url" | sed 's@\/\+@/@g;s@^\/*@@g')
      abs_url="$base_url/$normalized_path"
    fi

    if [ "$mode" = "verbose" ]; then
      print "Checking $abs_url"
      print "Check status of $abs_url"
    fi

    status_code=$(get_http_status "$abs_url")

    if [ "$status_code" -ne 200 ]; then
      error "Invalid code ($status_code): $abs_url"
      ((invalid += 1))
    else
      if [ "$mode" = "verbose" ]; then
        print "OK ($status_code)"
      fi
    fi

    ((all += 1))
  done

  if [ "$mode" = "verbose" ]; then
    echo
    print "Image URLs Invalid/All: $invalid/$all"
  fi
}

# public static void
function main() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    error "Provide URL of page (\$1) and absolute base URL (\$2) as arguments"
    exit 1
  fi

  local links=$(get_image_urls "$1")
  process_image_urls "$links" "$2" "$3"
}

if [ -z "$INCLUDE_IMAGE_URL_CHECKER" ]; then
  # shellcheck disable=SC2068
  main $@
fi
