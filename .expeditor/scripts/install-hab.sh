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

echo "--- :habicat: Installing Habitat 2.0.450"
rm -rf /hab
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash -s -- -v 2.0.450 -t "$hab_target"
hab license accept
