#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]; then
    echo "No LinuxArtifact parameter supplied. We need a target artifact to install"
    exit 1
fi

LINUX_ARTIFACT="$1"

# Read the CHEF_LICENSE_SERVER value from chef_license_server_url.txt
# Ideally, this value would have been read from a centralized environment such as a GitHub environment,
# Buildkite environment, or a vault, allowing for seamless updates without requiring a pull request for changes.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Use SCRIPT_DIR to refer to files relative to the script’s location
export CHEF_LICENSE_SERVER=$(cat "$SCRIPT_DIR/chef_license_server_url.txt")

echo "--- Installing habitat using ${SCRIPT_DIR}/install-hab.sh"
"${SCRIPT_DIR}/install-hab.sh" "x86_64-linux"

echo "--- Installing ${LINUX_ARTIFACT}"
hab pkg install "${LINUX_ARTIFACT}" --auth "${HAB_AUTH_TOKEN}"
if [[ $? -ne 0 ]]; then
    echo "ERROR: Unable to install ${LINUX_ARTIFACT}" >&2
    exit 1
fi

echo "--- Running habitat tests"
./habitat/tests/test.sh "${LINUX_ARTIFACT}"
