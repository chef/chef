set -e pipefail

git config --global --add safe.directory /workdir

echo "--- Downloading package artifact"
export PKG_ARTIFACT=$(buildkite-agent meta-data get "INFRA_HAB_ARTIFACT")
buildkite-agent artifact download "$PKG_ARTIFACT" .

echo ":key: Setting up origin key"
buildkite-agent artifact download "ci-key.pub" .
cat ci-key.pub | hab origin key import
if [ $? -ne 0 ]; then
  echo "Failed to import origin key"
  exit 1
fi

echo "--- Installing $PKG_ARTIFACT"
sudo hab pkg install $PKG_ARTIFACT

pkg_ident=$(hab pkg path ci/chef-infra-client | grep -oP 'ci/chef-infra-client/[0-9]+\.[0-9]+\.[0-9]+/[0-9]+')
echo "--- Resolved package identifier: $pkg_ident, attempting to run tests"
./habitat/tests/test.sh "$pkg_ident"
