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

# Ensure docker buildx plugin is available (required for BuildKit --secret support
# and for the Dockerfile's RUN --mount=type=secret syntax).
#
# The Buildkite docker-login plugin sets DOCKER_CONFIG to a temp directory (e.g.
# /tmp/tmp.XXXXX). Docker CLI resolves plugins from $DOCKER_CONFIG/cli-plugins/,
# so we must install buildx there — not ~/.docker/ (invisible when DOCKER_CONFIG
# is overridden) and not /usr/local/lib/docker/ (requires root).
if ! docker buildx version &>/dev/null; then
  echo "--- docker buildx not found; installing plugin"
  BUILDX_VERSION="v0.20.1"
  BUILDX_PLUGIN_DIR="${DOCKER_CONFIG:-${HOME}/.docker}/cli-plugins"
  mkdir -p "${BUILDX_PLUGIN_DIR}"
  curl -fsSL \
    "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${arch}" \
    -o "${BUILDX_PLUGIN_DIR}/docker-buildx"
  chmod +x "${BUILDX_PLUGIN_DIR}/docker-buildx"
  docker buildx version
fi

export DOCKER_BUILDKIT=1

# Use --secret instead of --build-arg for sensitive data (token never baked into layers)
docker build \
  --build-arg "CHANNEL=${channel}" \
  --build-arg "VERSION=${version}" \
  --build-arg "ARCH=${dockerfile_arch}" \
  --secret id=hab_token,env=HAB_AUTH_TOKEN \
  -t "chef/chef-hab:${version}-${arch}" .

echo "--- Pushing chef/chef-hab:${version} docker image for ${arch} to dockerhub"
docker push "chef/chef-hab:${version}-${arch}"
