#! /bin/bash
set -eu -o pipefail

arch=$1

if [[ $arch == "arm64" ]]; then
  dockerfile_pkg_version="7"
  dockerfile_arch="aarch64"
else
  dockerfile_pkg_version="6"
  dockerfile_arch="x86_64"
fi

channel="${EXPEDITOR_CHANNEL:-unstable}"
version="${EXPEDITOR_VERSION:?You must manually set the EXPEDITOR_VERSION environment variable to an existing semantic version.}"

echo "--- Building chef/chef:${version} docker image for ${arch}"
docker build \
  --build-arg "CHANNEL=${channel}" \
  --build-arg "VERSION=${version}" \
  --build-arg "ARCH=${dockerfile_arch}" \
  --build-arg "PKG_VERSION=${dockerfile_pkg_version}" \
  -t "chef/chef:${version}-${arch}" .

echo "--- Pushing chef/chef:${version} docker image for ${arch} to dockerhub"
docker push "chef/chef:${version}-${arch}"