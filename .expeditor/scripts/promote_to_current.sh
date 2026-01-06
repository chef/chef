#!/bin/bash
set -euo pipefail

echo "===================================================="
echo "  Chef Promotion: Promote Artifacts to Current"
echo "===================================================="

# (Optional) Define variables here, e.g. artifact location, S3 bucket, Artifactory repo, etc.
ARTIFACTS_DIR="pkg" # Example directory where the build artifacts are stored
PROMOTE_DESTINATION="current" # Destination folder/name for promotion

# Check artifacts exist
if [[ ! -d "$ARTIFACTS_DIR" ]]; then
  echo "ERROR: Artifacts directory '$ARTIFACTS_DIR' does not exist!"
  exit 1
fi

echo "Found artifacts in $ARTIFACTS_DIR. Promoting to '$PROMOTE_DESTINATION'..."

echo "===================================================="
echo "  Chef-Infra-Client Hab packages  Promotion: Promote to Current Channel  "
echo "===================================================="

# Source promotion settings :
# - ARTIFACTORY_API_TOKEN
# - PROJECT_NAME
# - BUILD_VERSION
# - ARTIFACTORY_ENDPOINT
build_version="$(buildkite-agent meta-data get "${project_name}_build_version")" || true
artifactory_api_token="$(vault read -field token account/static/artifactory/buildkite)"
export ARTIFACTORY_ENDPOINT="$artifactory_endpoint"
export ARTIFACTORY_API_TOKEN="$artifactory_api_token"
export PROJECT_NAME="$project_name"
user="buildkite"

comment="Promoted by Buildkite build ${BUILDKITE_BUILD_URL:-}"

echo "--- Promoting $PROJECT_NAME $BUILD_VERSION to 'current' channel in Artifactory..."
curl -fSL \
  -H "X-JFrog-Art-Api:${ARTIFACTORY_API_TOKEN}" \
  -XPOST \
  "${ARTIFACTORY_ENDPOINT}/api/plugins/build/promote/current/${PROJECT_NAME}/${BUILD_VERSION}" \
  -G --data-urlencode "params=comment=${comment}|user=${user}"
PROMOTION_STATUS=$?

if [[ $PROMOTION_STATUS -eq 0 ]]; then
  echo "===================================================="
  echo "     Promotion to 'current' channel completed!      "
  echo "===================================================="
else
  echo "ERROR: Promotion to 'current' channel failed."
  exit 2
fi 
