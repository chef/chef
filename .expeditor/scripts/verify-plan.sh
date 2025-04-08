#!/usr/bin/env bash

set -euo pipefail

export HAB_ORIGIN='ci'
export PLAN='chef-infra-client'
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

echo "--- :8ball: :linux: Verifying $PLAN"
project_root="$(git rev-parse --show-toplevel)"

echo "--- :key: Generating fake origin key"
hab origin key generate "$HAB_ORIGIN"

echo "--- :construction: Building $PLAN (solely for verification testing)"
(
  cd "$project_root" || error 'cannot change directory to project root'
  DO_CHECK=true hab pkg build . || error 'unable to build'
)

source "${project_root}/results/last_build.env" || error 'unable to determine details about this build'

echo "--- :hammer_and_wrench: Installing $pkg_ident"
hab pkg install "${project_root}/results/$pkg_artifact" || error 'unable to install this build'

# echo "--- :mag_right: Testing $PLAN"
# ${project_root}/habitat/tests/test.sh "$pkg_ident" || error 'failures during test of executables'

echo "--- :gem: Verifying no outdated REXML gem versions exist"
rexml_output=$(hab pkg exec "$pkg_ident" gem list rexml)
echo "REXML gem versions: $rexml_output"
# Print REXML gem installation path
rexml_path=$(hab pkg exec "$pkg_ident" gem which rexml)
echo "REXML gem path: $rexml_path"
# Print REXML gem versions
if [[ $rexml_output =~ rexml\ \(([0-9.,\ ]+)\) ]]; then
  versions=$(echo "${BASH_REMATCH[1]}" | tr ',' '\n' | xargs)
  min_version="3.3.6"
  outdated_versions=()

  for version in $versions; do
    if [[ $(printf '%s\n' "$version" "$min_version" | sort -V | head -n1) == "$version" && "$version" != "$min_version" ]]; then
      outdated_versions+=("$version")
    fi
  done

  if [[ ${#outdated_versions[@]} -gt 0 ]]; then
    echo "ERROR: Found outdated REXML gem versions: ${outdated_versions[*]}. Minimum required version is $min_version."
    exit 1
  else
    echo "REXML version check passed. No outdated versions found."
  fi
else
  echo "ERROR: Unable to determine REXML gem versions."
  exit 1
fi
