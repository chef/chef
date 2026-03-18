#!/usr/bin/env bash

# Uploads the aarch64-linux habitat package to the habitat builder.
# Expeditor's built-in habitat/build pipeline does not support aarch64 targets,
# so this script handles the upload as part of the validate/release pipeline.

set -euo pipefail

export HAB_ORIGIN='chef'
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"

error () {
  local message="$1"
  echo -e "\nERROR: ${message}\n" >&2
  exit 1
}

echo "--- Downloading aarch64 package artifact"
PKG_ARTIFACT=$(buildkite-agent meta-data get "INFRA_HAB_ARTIFACT_LINUX_AARCH64")
buildkite-agent artifact download "$PKG_ARTIFACT" . || error 'unable to download aarch64 artifact'

echo "--- :habicat: Uploading aarch64 package to habitat builder (unstable channel)"
hab pkg upload "$PKG_ARTIFACT" --auth "$HAB_AUTH_TOKEN" --channel unstable || error 'unable to upload aarch64 package to habitat builder'

echo "--- Successfully uploaded $PKG_ARTIFACT to habitat builder"
