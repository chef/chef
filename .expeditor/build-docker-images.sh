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

# ------------------------------------------------------------------
# Ensure docker-buildx is available (required by Docker 29.x+)
# Docker 29+ enables BuildKit by default and requires the buildx plugin.
# This self-heals on hosts where buildx is not yet baked into the AMI.
# ------------------------------------------------------------------
ensure_buildx() {
  if docker buildx version &>/dev/null; then
    return 0
  fi

  echo "--- Installing docker-buildx plugin (not found on host) ---"
  BUILDX_VERSION="${DOCKER_BUILDX_VERSION:-v0.21.1}"
  case "$(uname -m)" in
    x86_64)  BUILDX_ARCH="linux-amd64" ;;
    aarch64) BUILDX_ARCH="linux-arm64" ;;
    *)       echo "ERROR: Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac

  install_buildx() {
    local plugin_dir="$1"
    mkdir -p "${plugin_dir}"
    curl -fsSL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.${BUILDX_ARCH}" \
      -o "${plugin_dir}/docker-buildx"
    chmod +x "${plugin_dir}/docker-buildx"
  }

  # Try user plugin dir first
  install_buildx "${HOME}/.docker/cli-plugins"

  # Retry and fall back to a system plugin dir if needed
  if ! docker buildx version &>/dev/null; then
    if [[ -w "/usr/local/lib/docker/cli-plugins" ]]; then
      install_buildx "/usr/local/lib/docker/cli-plugins"
    elif command -v sudo &>/dev/null; then
      sudo mkdir -p "/usr/local/lib/docker/cli-plugins"
      sudo curl -fsSL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.${BUILDX_ARCH}" \
        -o "/usr/local/lib/docker/cli-plugins/docker-buildx"
      sudo chmod +x "/usr/local/lib/docker/cli-plugins/docker-buildx"
    fi
  fi

  if ! docker buildx version &>/dev/null; then
    echo "ERROR: docker-buildx install failed; docker buildx still unavailable"
    exit 1
  fi

  echo "Installed docker-buildx $(docker buildx version)"
}

ensure_buildx

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
