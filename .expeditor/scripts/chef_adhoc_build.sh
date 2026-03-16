#!/usr/bin/env bash

set -euo pipefail

hab_target="${1:-x86_64-linux}"

./.expeditor/scripts/install-hab.sh "$hab_target"

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

if [[ "$hab_target" == "aarch64-linux" ]]; then
  meta_key="INFRA_HAB_ARTIFACT_LINUX_AARCH64"
else
  meta_key="INFRA_HAB_ARTIFACT_LINUX"
fi

echo "--- Setting ${meta_key} metadata for buildkite agent"
echo "setting ${meta_key} to $pkg_artifact"
buildkite-agent meta-data set "$meta_key" "$pkg_artifact"
