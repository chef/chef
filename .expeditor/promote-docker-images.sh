#! /bin/bash
set -eou pipefail

export DOCKER_CLI_EXPERIMENTAL=enabled
# set expeditor_version equal to the version file
export EXPEDITOR_VERSION=$(cat VERSION)

# Determine channel from project_promoted context (source/target channels)
# If running in project_promoted workload, EXPEDITOR_TARGET_CHANNEL is set
# Otherwise fall back to EXPEDITOR_CHANNEL for other workload types
if [[ -n "${EXPEDITOR_TARGET_CHANNEL:-}" ]]; then
  # Running in project_promoted workload - promoting from source to target
  channel="${EXPEDITOR_TARGET_CHANNEL}"
  source_channel="${EXPEDITOR_SOURCE_CHANNEL:-unknown}"
  echo "--- Promoting from ${source_channel} to ${channel}"
else
  # Fallback for other workload types
  channel="${EXPEDITOR_CHANNEL:-unstable}"
  echo "--- Promoting within channel: ${channel}"
fi

version="${EXPEDITOR_VERSION:?ERROR: EXPEDITOR_VERSION not set or VERSION file not found}"

# Authenticate with Docker
docker_login_user="expeditor"
docker_login_password="$(vault read -field=expeditor-full-access secret/docker/expeditor 2>/dev/null)" || {
  echo "ERROR: Could not fetch Docker credentials from vault"
  exit 1
}

echo "--- Logging into Docker Hub"
docker login -u "$docker_login_user" -p "$docker_login_password" || {
  echo "ERROR: Docker login failed"
  exit 1
}

# Helper function to create and push a multi-arch manifest
# This manifests includes BOTH amd64 and arm64 images
function create_and_push_manifest() {
  local manifest_tag="$1"
  local source_images=("chef/chef-hab:${version}-amd64" "chef/chef-hab:${version}-arm64")

  echo "--- Creating manifest chef/chef-hab:${manifest_tag}"

  # Check that both source images exist
  for img in "${source_images[@]}"; do
    echo "    Verifying ${img} exists..."
    docker manifest inspect "${img}" > /dev/null 2>&1 || {
      echo "ERROR: Source image ${img} not found on Docker Hub"
      return 1
    }
  done

  # Create manifest combining both architectures
  docker manifest create "chef/chef-hab:${manifest_tag}" \
    --amend "${source_images[0]}" \
    --amend "${source_images[1]}"

  echo "--- Pushing manifest chef/chef-hab:${manifest_tag}"
  docker manifest push "chef/chef-hab:${manifest_tag}"
}

# Parse version into components: 19.1.163 → major=19, minor=1, patch=163
declare -i major_version minor_version _patch_version
IFS="."; read -r major_version minor_version _patch_version <<< "$version"

echo "--- Version breakdown: major=${major_version}, minor=${minor_version}, patch=${_patch_version}"

# Create appropriate tags based on target channel
case "$channel" in
  current)
    # For 'current' channel: create major and major.minor version tags
    # These tags represent the latest pre-release versions
    echo "--- Creating current channel tags"
    create_and_push_manifest "${major_version}"
    create_and_push_manifest "${major_version}.${minor_version}"
    create_and_push_manifest "current"
    ;;

  stable)
    # For 'stable' channel: create all major, minor, AND floating stable/latest tags
    # These are the recommended production-ready releases
    echo "--- Creating stable channel tags"
    create_and_push_manifest "${major_version}"
    create_and_push_manifest "${major_version}.${minor_version}"
    create_and_push_manifest "stable"
    create_and_push_manifest "latest"
    ;;

  unstable)
    # For 'unstable' channel: only create version-specific tags
    # Floating tags (19, 19.1, etc) should not be used for unstable builds
    echo "--- Creating unstable channel tags (version-specific only)"
    create_and_push_manifest "unstable"
    ;;
esac

echo "--- Successfully promoted chef/chef-hab:${version} to ${channel}"
echo "--- Available Docker tags for this release:"
docker manifest inspect "chef/chef-hab:${version}-amd64" | jq '.Descriptor.digest' 2>/dev/null || true
