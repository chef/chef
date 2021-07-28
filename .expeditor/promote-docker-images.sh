#! /bin/bash

export DOCKER_CLI_EXPERIMENTAL=enabled

function create_and_push_manifest() {
  echo "--- Creating manifest for ${1}"
  docker manifest create "chef/chef:${1}" \
    --amend "chef/chef:${EXPEDITOR_VERSION}-arm64" \
    --amend "chef/chef:${EXPEDITOR_VERSION}-amd64"

  echo "--- Pushing manifest for ${1}"
  docker manifest push "chef/chef:${1}"
}

# unstable, stable, current
create_and_push_manifest "${EXPEDITOR_TARGET_CHANNEL}"

if [[ $EXPEDITOR_TARGET_CHANNEL == "stable" ]]; then
  create_and_push_manifest "latest"

  # split the version and add the tags for major and major.minor
  version=(${EXPEDITOR_VERSION//./ })

  # major version
  create_and_push_manifest "${version[0]}"

  # major.minor version
  create_and_push_manifest "${version[0]}.${version[1]}"
fi