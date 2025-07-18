#!/usr/bin/env bash

set -euo pipefail

echo "--- Checking HAB_AUTH_TOKEN"
if [ -z "${HAB_AUTH_TOKEN:-}" ]; then
  echo "HAB_AUTH_TOKEN is not set"
else
  echo "HAB_AUTH_TOKEN is set"
fi

./.expeditor/scripts/install-hab.sh x86_64-linux

echo "--- Installing Chef Infra Client from unstable channel via Habitat"
hab pkg install chef/chef-infra-client --channel unstable

echo "--- Setting INFRA_HAB_PKG_IDENT metadata for buildkite agent"
export PKG_IDENT=$(hab pkg path chef/chef-infra-client | grep -oP 'chef/chef-infra-client/[0-9]+\.[0-9]+\.[0-9]+/[0-9]+')
echo "setting INFRA_HAB_PKG_IDENT to $PKG_IDENT"
buildkite-agent meta-data set "INFRA_HAB_PKG_IDENT" "$PKG_IDENT"
