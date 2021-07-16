#! /bin/bash

export DOCKER_CLI_EXPERIMENTAL=enabled

arch=$1

echo "--- Building chef/chef:${EXPEDITOR_VERSION} docker image for ${arch}"
docker build \
  --build-arg "CHANNEL=${EXPEDITOR_CHANNEL}" \
  --build-arg "VERSION=${EXPEDITOR_VERSION}" \
  -t "chef/chef:${EXPEDITOR_VERSION}-${arch}" .

echo "--- Pushing chef/chef:${EXPEDITOR_VERSION} docker image for ${arch} to dockerhub"
docker push "chef/chef:${EXPEDITOR_VERSION}-${arch}"

echo "--- Creating chef/chef:${EXPEDITOR_VERSION} multiarch manifest"
docker manifest create "chef/chef:${EXPEDITOR_VERSION}" \
  --amend "chef/chef:${EXPEDITOR_VERSION}-${arch}"

echo "--- Pushing chef/chef:${EXPEDITOR_VERSION} multiarch manifest"
docker manifest push "chef/chef:${EXPEDITOR_VERSION}"