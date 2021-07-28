#! /bin/bash
set -eu -o pipefail

export DOCKER_CLI_EXPERIMENTAL=enabled

function create_and_push_manifest() {
  manifest_tag="${1}"

  echo "--- Creating manifest for ${manifest_tag}"
  docker manifest create "chef/chef:${manifest_tag}" \
    --amend "chef/chef:${EXPEDITOR_VERSION}-arm64" \
    --amend "chef/chef:${EXPEDITOR_VERSION}-amd64"

  echo "--- Pushing manifest for ${manifest_tag}"
  docker manifest push "chef/chef:${manifest_tag}"
}

# create the initial version and initial channel docker images
create_and_push_manifest "${EXPEDITOR_VERSION}"
create_and_push_manifest "${EXPEDITOR_CHANNEL}"