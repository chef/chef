#!/bin/bash

set -eou pipefail

export HAB_ORIGIN="chef"
export CHEF_LICENSE="accept-no-persist"
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="LTS-2024"
export PROJECT_NAME="chef"
export ARTIFACTORY_ENDPOINT="https://artifactory-internal.ps.chef.co/artifactory"
export ARTIFACTORY_USERNAME="buildkite"
export GEM_HOST_API_KEY="Basic ${ARTIFACTORY_API_KEY}"

gem install artifactory -v 3.0.17 --no-document

echo "Generating origin key"
hab origin key generate "$HAB_ORIGIN"

echo "Building gems via habitat"
hab pkg build . --refresh-channel LTS-2024 || echo "failed to build package"

echo "Push gems to artifactory"
ruby .expeditor/scripts/chef_gem_publish.rb