#! /bin/bash
set -eu -o pipefail

export DOCKER_CLI_EXPERIMENTAL=enabled

channel="${EXPEDITOR_CHANNEL:-unstable}"
version="${EXPEDITOR_VERSION:?You must manually set the EXPEDITOR_VERSION environment variable to an existing semantic version.}"

docker_login_user="expeditor"
docker_login_password="$(vault read -field=expeditor-full-access secret/docker/expeditor)"

# login to docker
echo "--- Docker login so we can push to chef org"
docker login -u "$docker_login_user" -p "$docker_login_password"

function create_and_push_manifest() {
  local manifest_tag
  manifest_tag="$1"

  echo "--- Creating manifest for ${manifest_tag}"
  docker manifest create "chef/chef-hab:${manifest_tag}" \
    --amend "chef/chef-hab:${version}-amd64"
#    --amend "chef/chef-hab:${version}-arm64" # Commenting out the arm64 as we are not supporting it in RC1

  echo "--- Pushing manifest for ${manifest_tag}"
  docker manifest push "chef/chef-hab:${manifest_tag}"
}

# split the version components into integer variables
declare -i major_version minor_version _patch_version
IFS="."; read -r major_version minor_version _patch_version <<< "$version"

# mixlib-install uses package router's API which makes requests directly to Artifactory thereby providing up-to-date results
if mixlib-install download chef --url --channel stable --version "$major_version" &> /dev/null; then
  major_version_is_in_omnibus_stable="true"
else
  major_version_is_in_omnibus_stable="false"
fi

latest_major_version_in_omnibus_current="$(mixlib-install download chef --version latest --channel current --attributes --url | tail -n +2 | jq -r '.version | split(".")[0]')"
latest_major_version_in_omnibus_stable="$(mixlib-install download chef --version latest --channel stable --attributes --url | tail -n +2 | jq -r '.version | split(".")[0]')"

if [[ "$channel" == "current" ]]; then
  # Add major and major.minor version tags unless this major version has been promoted to the omnibus STABLE channel
  if [[ "$major_version_is_in_omnibus_stable" == "false" ]] ; then
    create_and_push_manifest "$major_version"
    create_and_push_manifest "${major_version}.${minor_version}"
  fi

  # Add "current" tag unless a newer major version has been promoted to the omnibus CURRENT channel
  if [[ $major_version -ge $latest_major_version_in_omnibus_current ]]; then
    create_and_push_manifest "current"
  fi
elif [[ "$channel" == "stable" ]]; then
  # Add major and major.minor version tags
  create_and_push_manifest "$major_version"
  create_and_push_manifest "${major_version}.${minor_version}"

  # Add "stable" tag unless a newer major version has been promoted to the omnibus STABLE channel
  if [[ $major_version -ge $latest_major_version_in_omnibus_stable ]]; then
    create_and_push_manifest "stable"

    # The "latest" docker tag is equivalent to the latest stable release
    create_and_push_manifest "latest"
  fi
else
  echo "ERROR: Channel $channel not recognized"
  exit 1
fi
