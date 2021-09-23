#! /bin/bash
set -eu -o pipefail

export DOCKER_CLI_EXPERIMENTAL=enabled

channel="${EXPEDITOR_CHANNEL:-unstable}"
version="${EXPEDITOR_VERSION:?You must manually set the EXPEDITOR_VERSION environment variable to an existing semantic version.}"

docker_login_user="expeditor"
docker_login_password="$(vault read -field=expeditor-full-access secret/docker/expeditor)"

# login to docker
echo "--- Docker login so we can push to chef org"
docker login -u "${docker_login_user}" -p "${docker_login_password}"

function create_and_push_manifest() {
  manifest_tag="${1}"

  echo "--- Creating manifest for ${manifest_tag}"
  docker manifest create "chef/chef:${manifest_tag}" \
    --amend "chef/chef:${version}-arm64" \
    --amend "chef/chef:${version}-amd64"

  echo "--- Pushing manifest for ${manifest_tag}"
  docker manifest push "chef/chef:${manifest_tag}"
}

# create the promoted channel docker image
create_and_push_manifest "${channel}"

if [[ ${channel} == "stable" ]]; then
  create_and_push_manifest "latest"

  # split the version and add the tags for major and major.minor
  IFS="."; read -ra split_version <<< "${version}"

  # major version
  create_and_push_manifest "${split_version[0]}"

  # major.minor version
  create_and_push_manifest "${split_version[0]}.${split_version[1]}"
fi