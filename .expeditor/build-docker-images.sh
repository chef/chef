#! /bin/bash
set -eu -o pipefail

arch=$1

echo "--- Building chef/chef:${EXPEDITOR_VERSION} docker image for ${arch}"
docker build \
  --build-arg "CHANNEL=${EXPEDITOR_CHANNEL}" \
  --build-arg "VERSION=${EXPEDITOR_VERSION}" \
  -t "chef/chef:${EXPEDITOR_VERSION}-${arch}" .

echo "--- Pushing chef/chef:${EXPEDITOR_VERSION} docker image for ${arch} to dockerhub"
docker push "chef/chef:${EXPEDITOR_VERSION}-${arch}"