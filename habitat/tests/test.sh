#!/usr/bin/env bash

set -euo pipefail

export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"

project_root="$(git rev-parse --show-toplevel)"
pkg_ident="$1"

# print error message followed by usage and exit
error () {
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

echo "--- :mag_right: Testing ${pkg_ident} functionality"
hab pkg exec "${pkg_ident}" rspec --tag ~executables --pattern 'spec/functional/**/*_spec.rb' --exclude-pattern 'spec/functional/knife/**/*.rb' || error 'failures during rspec tests'
