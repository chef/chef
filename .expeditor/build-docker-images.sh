#! /bin/bash
set -eu -o pipefail

arch=$1
channel="${EXPEDITOR_CHANNEL:-unstable}"
version="${EXPEDITOR_VERSION:?You must manually set the EXPEDITOR_VERSION environment variable to an existing semantic version.}"

echo "--- Building chef/chef:${version} docker image for ${arch}"
docker build \
  --build-arg "CHANNEL=${channel}" \
  --build-arg "VERSION=${version}" \
  -t "chef/chef:${version}-${arch}" .

echo "--- Pushing chef/chef:${version} docker image for ${arch} to dockerhub"
docker push "chef/chef:${version}-${arch}"