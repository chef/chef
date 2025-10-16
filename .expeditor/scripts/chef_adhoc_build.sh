#!/usr/bin/env bash

set -euo pipefail

./.expeditor/scripts/install-hab.sh x86_64-linux

export HAB_ORIGIN='chef'
export PLAN='chef-infra-client'
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="base-2025"

echo "--- :key: Downloading origin keys"
hab origin key download "$HAB_ORIGIN"
hab origin key download "$HAB_ORIGIN" --secret

echo "--- Building Chef Infra Client package"
hab pkg build . --refresh-channel base-2025 || error 'unable to build'

project_root="$(git rev-parse --show-toplevel)"
source "${project_root}/results/last_build.env" || error 'unable to determine details about this build'

echo "--- :package: Uploading package"
cd "${project_root}/results"
buildkite-agent artifact upload "$pkg_artifact" || error 'unable to upload package'

echo "--- Setting INFRA_HAB_ARTIFACT_LINUX metadata for buildkite agent"
echo "setting INFRA_HAB_ARTIFACT_LINUX to $pkg_artifact"
buildkite-agent meta-data set "INFRA_HAB_ARTIFACT_LINUX" "$pkg_artifact"
