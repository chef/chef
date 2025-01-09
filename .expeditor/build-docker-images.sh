#! /bin/bash
set -eux -o pipefail

arch=$1

# dockerfile_pkg_version is the enterprise linux version of packages to install
# for maximum compatibility with various OSs' use the lowest version still supported to get the minimal gcc version available
# using latest el version may have pkg versions higher than what is available in older OS versions
if [[ $arch == "arm64" ]]; then
  dockerfile_pkg_version="8"
  dockerfile_arch="aarch64"
else
  dockerfile_pkg_version="8"
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
