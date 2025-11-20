#!/bin/bash

set -eou pipefail

export HAB_ORIGIN="chef"
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="base-2025"
export PROJECT_NAME="chef"
export ARTIFACTORY_ENDPOINT="https://artifactory-internal.ps.chef.co/artifactory"
export ARTIFACTORY_USERNAME="buildkite"

# Debug output
#echo "Script: HAB_AUTH_TOKEN=$HAB_AUTH_TOKEN"

# # error if hab_auth_token is not set
# if [ -z "${HAB_AUTH_TOKEN:-}" ]; then
#   echo "HAB_AUTH_TOKEN is not set. Exiting."
#   exit 1
# fi

lita_password=$(aws ssm get-parameter --name "artifactory-lita-password" --with-decryption --query Parameter.Value --output text --region us-west-2)
artifactory_api_key=$(echo -n "lita:${lita_password}" | base64)
export GEM_HOST_API_KEY="Basic ${artifactory_api_key}"

echo "Generating origin key"
hab origin key generate "$HAB_ORIGIN"

echo "Building gems via habitat"
hab pkg build . --channel base-2025 || echo "failed to build package"

echo "Push gems to artifactory"
gem install artifactory -v 3.0.17 --no-document
ruby .expeditor/scripts/gem_push_artifactory.rb
