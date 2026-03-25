#!/usr/bin/env bash

set -euo pipefail

export HAB_LICENSE="accept"
export HAB_NONINTERACTIVE="true"

hab_target="$1"
hab_version="1.6.1245"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

[[ -n "$hab_target" ]] || error 'no hab target provided'

echo "--- :habicat: Installing Habitat ${hab_version}"
rm -rf /hab
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash -s -- -v "$hab_version" -t "$hab_target"
hab license accept
