#!/usr/bin/env bash
# Darwin (macOS) test script for the chef-infra-client Habitat package.
# Usage: ./habitat/tests/test.darwin.sh <pkg_ident>
#   pkg_ident: e.g. rishichawda/chef-infra-client/19.3.24/20260602032309

set -euo pipefail

export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="base-2025"

project_root="$(git rev-parse --show-toplevel)"
pkg_ident="$1"

# print error message and exit
error() {
  local message="$1"
  echo -e "\nERROR: ${message}\n" >&2
  exit 1
}

[[ -n "$pkg_ident" ]] || error 'no hab package identity provided'

package_version=$(awk -F / '{print $3}' <<<"$pkg_ident")

cd "${project_root}"

echo "--- :mag_right: Testing ${pkg_ident} executables"
actual_version=$(hab pkg exec "${pkg_ident}" chef-client -- --version | sed 's/.*: //')
[[ "$package_version" = "$actual_version" ]] || error "chef-client is not the expected version. Expected '$package_version', got '$actual_version'"

for executable in 'chef-client' 'ohai' 'chef-shell' 'chef-apply' 'chef-solo'; do
  echo -en "\t$executable = "
  hab pkg exec "${pkg_ident}" "${executable}" -- --version || error "${executable} failed to execute properly"
done

# On macOS, use DYLD_LIBRARY_PATH instead of LD_LIBRARY_PATH to make
# libarchive available to the Ruby runtime during tests.
export DYLD_LIBRARY_PATH="$(hab pkg path core/libarchive)/lib"

echo "--- :construction: Gotta find RSPEC so testing doesn't immediately fail"
results=($(find /hab/pkgs -name "rspec" -type f))
echo "${results[1]}"

echo "--- :mag_right: Testing ${pkg_ident} functionality"
# rspec is not on the path by default; insert the directory we found above.
rspec_path=$(dirname "${results[1]}")
export PATH="${rspec_path}:${PATH}"
export HAB_TEST="true"

hab pkg exec "${pkg_ident}" rspec --profile -f documentation -- ./spec/unit
hab pkg exec "${pkg_ident}" rspec --profile -f documentation -- ./spec/functional
hab pkg exec "${pkg_ident}" rspec --profile -f documentation -- ./spec/integration
