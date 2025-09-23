#!/usr/bin/env bash

set -euo pipefail

export HAB_ORIGIN='chef'
export PLAN='chef-infra-client'
export CHEF_LICENSE="accept-no-persist"
# Read the CHEF_LICENSE_SERVER value from chef_license_server_url.txt
# Ideally, this value would have been read from a centralized environment such as a GitHub environment,
# Buildkite environment, or a vault, allowing for seamless updates without requiring a pull request for changes.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Use SCRIPT_DIR to refer to files relative to the script’s location
export CHEF_LICENSE_SERVER=$(cat "$SCRIPT_DIR/chef_license_server_url.txt")
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="base-2025"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

echo "--- :habicat: Patching /etc/nsswitch.conf to ensure 'files' is listed first and that we remove myhostname"
sed -i 's/hosts:      files dns myhostname/hosts:      files dns/g' /etc/nsswitch.conf
sed -i 's/networks:   files dns/networks:   files/g' /etc/nsswitch.conf

echo "--- :git: Configuring git safe directory"
git config --global --add safe.directory /workdir

echo "--- :8ball: :linux: Verifying $PLAN"
project_root="$(git rev-parse --show-toplevel)"

echo "--- :key: Generating fake origin key"
hab origin key generate "$HAB_ORIGIN"

echo "--- :construction: Building $PLAN (solely for verification testing)"
(
  cd "$project_root" || error 'cannot change directory to project root'
  DO_CHECK=true hab pkg build . --refresh-channel base-2025 || error 'unable to build'
)

source "${project_root}/results/last_build.env" || error 'unable to determine details about this build'

echo "--- :hammer_and_wrench: Installing $pkg_ident"
hab pkg install "${project_root}/results/$pkg_artifact" || error 'unable to install this build'

echo "--- :mag_right: Testing $PLAN"
${project_root}/habitat/tests/test.sh "$pkg_ident" || error 'failures during test of executables'
