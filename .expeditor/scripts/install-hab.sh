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
echo "****************DEBUG STATEMENT **********"
export VAULT_ADDR="https://vault.ps.chef.co"

# Fetch ARTIFACTORY_TOKEN only if the organization is not chef-oss
if [[ ${BUILDKITE_ORGANIZATION_SLUG:-} != "chef-oss" ]]; then
  export ARTIFACTORY_TOKEN=""
  for i in {1..5}; do
    ARTIFACTORY_TOKEN=$(vault kv get -field token account/static/artifactory/buildkite) && break
    echo "Retrying Vault token fetch... ($i/5)"
    sleep 5
  done

  if [[ -z "$ARTIFACTORY_TOKEN" ]]; then
    echo "Failed to fetch ARTIFACTORY_TOKEN from Vault after 5 attempts."
    exit 1
  else
    echo "ARTIFACTORY_TOKEN is set successfully."
  fi
else
  echo "Skipping ARTIFACTORY_TOKEN fetch for chef-oss organization."
fi

export ARTIFACTORY_REPO_URL="https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local"

echo "--- :habicat: Installing latest version of Habitat"
rm -rf /hab
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash -s -- -t "$hab_target"
hab license accept
