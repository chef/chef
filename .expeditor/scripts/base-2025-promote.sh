#!/bin/bash

set -euo pipefail

echo "--- Promoting Habitat package from stable to base-2025"

# Expeditor provides these environment variables automatically
echo "Package Origin: ${EXPEDITOR_PKG_ORIGIN}"
echo "Package Name: ${EXPEDITOR_PKG_NAME}"
echo "Package Version: ${EXPEDITOR_PKG_VERSION}"
echo "Package Release: ${EXPEDITOR_PKG_RELEASE}"
echo "Package Ident: ${EXPEDITOR_PKG_IDENT}"
echo "Package Target: ${EXPEDITOR_PKG_TARGET}"
echo "Source Channel: ${EXPEDITOR_CHANNEL}"

# Set the target channel
TARGET_CHANNEL="base-2025"

# Get HAB_AUTH_TOKEN from vault
HAB_AUTH_TOKEN=$(vault kv get -field auth_token account/static/habitat/chef-ci)
export HAB_AUTH_TOKEN

echo "--- Promoting ${EXPEDITOR_PKG_IDENT} to ${TARGET_CHANNEL} channel"
hab pkg promote "${EXPEDITOR_PKG_IDENT}" "${TARGET_CHANNEL}"

echo "--- Promotion completed successfully!"
