set -e pipefail

echo "--- Setting CHEF_LICENSE_SERVER environment variable"
# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Use SCRIPT_DIR to refer to files relative to the script’s location
export CHEF_LICENSE_SERVER=$(cat "$SCRIPT_DIR/chef_license_server_url.txt")
echo "--- Script dir is $SCRIPT_DIR"
echo "--- License serverl url is $CHEF_LICENSE_SERVER"

git config --global --add safe.directory /workdir

echo "--- Downloading package artifact"
export PKG_ARTIFACT=$(buildkite-agent meta-data get "INFRA_HAB_ARTIFACT")
buildkite-agent artifact download "$PKG_ARTIFACT" .

echo ":key: Setting up origin key"
buildkite-agent artifact download "chef-key.pub" .
cat chef-key.pub | hab origin key import
if [ $? -ne 0 ]; then
  echo "Failed to import origin key"
  exit 1
fi

echo "--- Installing $PKG_ARTIFACT"
sudo hab pkg install $PKG_ARTIFACT --auth $HAB_AUTH_TOKEN --binlink

pkg_ident=$(hab pkg path chef/chef-infra-client | grep -oP 'chef/chef-infra-client/[0-9]+\.[0-9]+\.[0-9]+/[0-9]+')
echo "--- Resolved package identifier: $pkg_ident, attempting to run tests"
./habitat/tests/test.sh "$pkg_ident"
