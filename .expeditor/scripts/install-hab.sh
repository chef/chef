#!/usr/bin/env bash

set -euo pipefail

export HAB_LICENSE="accept"
export HAB_NONINTERACTIVE="true"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/hab-version.sh"

hab_target="$1"
hab_version="${2:-$HAB_VERSION}"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

[[ -n "$hab_target" ]] || error 'no hab target provided'
[[ -n "$hab_version" ]] || error 'no hab version provided'

echo "--- :habicat: Installing Habitat ${hab_version} for ${hab_target}"
rm -rf /hab
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash -s -- -t "$hab_target" -v "$hab_version"
hab license accept
