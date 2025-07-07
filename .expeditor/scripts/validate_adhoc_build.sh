set -e pipefail

echo "--- Installing $PKG_IDENT from unstable channel"
hab pkg install $PKG_IDENT --channel unstable --binlink

pkg_ident=$(hab pkg path chef/chef-infra-client | grep -oP 'chef/chef-infra-client/[0-9]+\.[0-9]+\.[0-9]+/[0-9]+')

echo "--- Resolved package identifier: $pkg_ident, attempting to run tests"
./habitat/tests/test.sh "$pkg_ident"
