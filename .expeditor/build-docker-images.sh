#! /bin/bash
set -eou pipefail

export EXPEDITOR_VERSION=$(cat VERSION)

arch=$1

if [[ $arch == "arm64" ]]; then
  dockerfile_arch="aarch64"
else
  dockerfile_arch="x86_64"
fi

channel="${EXPEDITOR_CHANNEL:-unstable}"
version="${EXPEDITOR_VERSION:?You must manually set the EXPEDITOR_VERSION environment variable to an existing semantic version.}"

# Verify HAB_AUTH_TOKEN is set for non-stable channels
if [[ "${channel}" != "stable" ]] && [[ -z "${HAB_AUTH_TOKEN:-}" ]]; then
  echo "ERROR: HAB_AUTH_TOKEN environment variable must be set for channel: ${channel}"
  exit 1
fi

echo "--- Building chef/chef-hab:${version} docker image for ${arch}"

# Enable BuildKit for secret support
export DOCKER_BUILDKIT=1

# Use --secret instead of --build-arg for sensitive data
docker build \
  --build-arg "CHANNEL=${channel}" \
  --build-arg "VERSION=${version}" \
  --build-arg "ARCH=${dockerfile_arch}" \
  --secret id=hab_token,env=HAB_AUTH_TOKEN \
  -t "chef/chef-hab:${version}-${arch}" .

echo "--- Pushing chef/chef-hab:${version} docker image for ${arch} to dockerhub"
docker push "chef/chef-hab:${version}-${arch}"
