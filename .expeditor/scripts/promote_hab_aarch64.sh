#!/bin/bash

# Promotes the aarch64-linux chef-infra-client package between habitat channels.
# Expeditor's built-in promote_habitat_packages does not support aarch64 targets,
# so this script handles it manually at each promotion stage.
#
# Context is auto-detected from EXPEDITOR_ environment variables:
#   - project_promoted:                    uses EXPEDITOR_SOURCE_CHANNEL → EXPEDITOR_TARGET_CHANNEL
#   - hab_package_published (stable):      uses EXPEDITOR_CHANNEL (stable) → base-2025
#   - buildkite_hab_build_group_published: defaults to unstable → current

set -euo pipefail

PKG_ORIGIN="chef"
PKG_NAME="chef-infra-client"
PKG_TARGET="aarch64-linux"

export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"

# Expeditor provides EXPEDITOR_PKG_VERSION for hab_package_published
# and EXPEDITOR_PROMOTABLE (which is the version) for project_promoted.
# For buildkite_hab_build_group_published, we extract it from pkg_idents.
PKG_VERSION="${EXPEDITOR_PKG_VERSION:-${EXPEDITOR_PROMOTABLE:-}}"

# Determine source and target channels based on Expeditor workload context
if [[ -n "${EXPEDITOR_TARGET_CHANNEL:-}" ]]; then
  # project_promoted workload
  SOURCE_CHANNEL="${EXPEDITOR_SOURCE_CHANNEL}"
  TARGET_CHANNEL="${EXPEDITOR_TARGET_CHANNEL}"
elif [[ -n "${EXPEDITOR_CHANNEL:-}" ]]; then
  # hab_package_published workload (e.g., stable)
  SOURCE_CHANNEL="${EXPEDITOR_CHANNEL}"
  TARGET_CHANNEL="base-2025"
else
  # buildkite_hab_build_group_published workload
  SOURCE_CHANNEL="unstable"
  TARGET_CHANNEL="current"
fi

echo "--- Promoting ${PKG_ORIGIN}/${PKG_NAME} (${PKG_TARGET}) from ${SOURCE_CHANNEL} to ${TARGET_CHANNEL}"

# Get auth token from vault (same pattern as base-2025-promote.sh)
HAB_AUTH_TOKEN=$(vault kv get -field auth_token account/static/habitat/chef-ci)
export HAB_AUTH_TOKEN

# Find the exact aarch64 package ident for this version
if [[ -n "$PKG_VERSION" ]]; then
  echo "--- Looking up ${PKG_TARGET} package for version ${PKG_VERSION}"
  PKG_IDENT=$(curl -sf "https://bldr.habitat.sh/v1/depot/pkgs/${PKG_ORIGIN}/${PKG_NAME}/${PKG_VERSION}/latest?target=${PKG_TARGET}" | jq -r '.ident_array | join("/")')
else
  echo "WARNING: No version info available. Skipping aarch64 promotion."
  exit 0
fi

if [[ -z "$PKG_IDENT" || "$PKG_IDENT" == "null" ]]; then
  echo "WARNING: No ${PKG_TARGET} package found for version ${PKG_VERSION}. Skipping promotion."
  exit 0
fi

echo "--- Found package: ${PKG_IDENT}"
echo "--- Promoting ${PKG_IDENT} to ${TARGET_CHANNEL} channel"

hab pkg promote "${PKG_IDENT}" "${TARGET_CHANNEL}" --target "${PKG_TARGET}"

echo "--- Successfully promoted ${PKG_IDENT} (${PKG_TARGET}) to ${TARGET_CHANNEL}"
