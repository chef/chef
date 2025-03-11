#!/bin/bash

set -eou pipefail

# echo "Installing dependencies.."
# bundle config set --local without docgen chefstyle development test
# bundle install --jobs=2 --retry=3 --without docgen chefstyle development test

# echo "Running post-bundle-install.rb.."
# ruby post-bundle-install.rb

# echo "Building gems.."
# rake install:local
# gem build chef.gemspec

lita_password=$(aws ssm get-parameter --name "artifactory-lita-password" --with-decryption --query Parameter.Value --output text --region ${AWS_REGION})
export ARTIFACTORY_API_KEY=$(echo -n "lita:${lita_password}" | base64)

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