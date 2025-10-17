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
export VAULT_ADDR="https://vault.ps.chef.co"
export ARTIFACTORY_TOKEN=$(vault kv get -field token account/static/artifactory/buildkite)
export ARTIFACTORY_REPO_URL="https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local"

echo "--- :habicat: Installing latest version of Habitat"
rm -rf /hab
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash -s -- -t "$hab_target"
hab license accept
