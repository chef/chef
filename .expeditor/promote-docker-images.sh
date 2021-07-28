#! /bin/bash

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

# create the promoted channel docker image
create_and_push_manifest "${EXPEDITOR_CHANNEL}"

if [[ ${EXPEDITOR_CHANNEL} == "stable" ]]; then
  create_and_push_manifest "latest"

  # split the version and add the tags for major and major.minor
  version=(${EXPEDITOR_VERSION//./ })

  # major version
  create_and_push_manifest "${version[0]}"

  # major.minor version
  create_and_push_manifest "${version[0]}.${version[1]}"
fi