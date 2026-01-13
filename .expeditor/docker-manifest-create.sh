#! /bin/bash
set -eu -o pipefail

export DOCKER_CLI_EXPERIMENTAL=enabled

channel="${EXPEDITOR_CHANNEL:-unstable}"
version="${EXPEDITOR_VERSION:?You must manually set the EXPEDITOR_VERSION environment variable to an existing semantic version.}"

function create_and_push_manifest() {
  manifest_tag="${1}"

  echo "--- Creating manifest for ${manifest_tag}"
  docker manifest create "chef/chef:${manifest_tag}" \
    --amend "chef/chef:${version}-arm64" \
    --amend "chef/chef:${version}-amd64"

  echo "--- Pushing manifest for ${manifest_tag}"
  docker manifest push "chef/chef:${manifest_tag}"
}

# create the initial version and initial channel docker images
create_and_push_manifest "${version}"
create_and_push_manifest "${channel}"