#! /bin/bash

export DOCKER_CLI_EXPERIMENTAL=enabled

echo "--- Creating chef/chef:${EXPEDITOR_VERSION} multiarch manifest"
docker manifest create "chef/chef:${EXPEDITOR_VERSION}" \
  --amend "chef/chef:${EXPEDITOR_VERSION}-amd64" \
  --amend "chef/chef:${EXPEDITOR_VERSION}-arm64"

echo "--- Pushing chef/chef:${EXPEDITOR_VERSION} multiarch manifest"
docker manifest push "chef/chef:${EXPEDITOR_VERSION}"