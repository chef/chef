#!/usr/bin/env bash

set -euo pipefail

export HAB_ORIGIN='ci'
export PLAN='chef-infra-client'
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

echo "--- :8ball: :linux: Verifying $PLAN"
project_root="$(git rev-parse --show-toplevel)"

echo "--- :key: Generating fake origin key"
hab origin key generate "$HAB_ORIGIN"

echo "--- :construction: Building $PLAN (solely for verification testing)"
(
  cd "$project_root" || error 'cannot change directory to project root'
  DO_CHECK=true hab pkg build . || error 'unable to build'
)

source "${project_root}/results/last_build.env" || error 'unable to determine details about this build'

echo "--- :hammer_and_wrench: Installing $pkg_ident"
hab pkg install "${project_root}/results/$pkg_artifact" || error 'unable to install this build'

echo "--- :mag_right: Testing $PLAN"
${project_root}/habitat/tests/test.sh "$pkg_ident" || error 'failures during test of executables'
