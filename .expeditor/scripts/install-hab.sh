#!/usr/bin/env bash

set -euo pipefail

export HAB_LICENSE="accept"
export HAB_NONINTERACTIVE="true"

hab_target="$1"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

[[ -n "$hab_target" ]] || error 'no hab target provided'

echo "--- :habicat: Installing latest version of Habitat"
rm -rf /hab
curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | bash -s -- -t "$hab_target"
hab license accept
