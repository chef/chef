#!/usr/bin/env bash
set -euo pipefail

export HAB_ORIGIN='chef'
export PLAN='chef-infra-client'
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="base-2025"

echo "--- Setting CHEF_LICENSE_SERVER environment variable"
# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Use SCRIPT_DIR to refer to files relative to the script’s location
export CHEF_LICENSE_SERVER=$(cat "$SCRIPT_DIR/chef_license_server_url.txt")
echo "--- Script dir is $SCRIPT_DIR"
echo "--- License serverl url is $CHEF_LICENSE_SERVER"

git config --global --add safe.directory /workdir

echo "--- Downloading package artifact"
arch=$(uname -m)
if [[ $arch == "aarch64" ]]; then
  artifact_key="INFRA_HAB_ARTIFACT_LINUX_AARCH64"
else
  artifact_key="INFRA_HAB_ARTIFACT_LINUX"
fi
export PKG_ARTIFACT=$(buildkite-agent meta-data get "$artifact_key")
buildkite-agent artifact download "$PKG_ARTIFACT" .

echo ":key: Downloading origin key"
hab origin key download "$HAB_ORIGIN"
if [ $? -ne 0 ]; then
  echo "Failed to download origin key"
  exit 1
fi

echo "--- Installing $PKG_ARTIFACT"
sudo hab pkg install $PKG_ARTIFACT --auth $HAB_AUTH_TOKEN --binlink

pkg_ident=$(hab pkg list "$HAB_ORIGIN"/"$PLAN")
echo "--- Resolved package identifier: $pkg_ident, attempting to run tests"
./habitat/tests/test.sh "$pkg_ident"
