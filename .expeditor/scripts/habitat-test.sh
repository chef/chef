#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]; then
    echo "No LinuxArtifact parameter supplied. We need a target artifact to install"
    exit 1
fi

LINUX_ARTIFACT="$1"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
