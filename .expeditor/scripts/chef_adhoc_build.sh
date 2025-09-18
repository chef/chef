#!/usr/bin/env bash

set -euo pipefail

./.expeditor/scripts/install-hab.sh x86_64-linux

export HAB_ORIGIN='chef'
export PLAN='chef-infra-client'
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="base-2025"

echo "--- :key: Generating fake origin key"
hab origin key generate "$HAB_ORIGIN"

echo "--- Building Chef Infra Client package"
hab pkg build . --refresh-channel base-2025 || error 'unable to build'

project_root="$(git rev-parse --show-toplevel)"
source "${project_root}/results/last_build.env" || error 'unable to determine details about this build'

echo "--- :package: Uploading package"
cd "${project_root}/results"
buildkite-agent artifact upload "$pkg_artifact" || error 'unable to upload package'

echo "--- Setting INFRA_HAB_ARTIFACT metadata for buildkite agent"
echo "setting INFRA_HAB_ARTIFACT to $pkg_artifact"
buildkite-agent meta-data set "INFRA_HAB_ARTIFACT" "$pkg_artifact"
hab origin key export "$HAB_ORIGIN" > "${project_root}/results/${HAB_ORIGIN}-key.pub"
buildkite-agent artifact upload "${HAB_ORIGIN}-key.pub"
