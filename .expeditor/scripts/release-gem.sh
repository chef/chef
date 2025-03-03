#!/bin/bash

set -eou pipefail

echo "Installing dependencies.."
bundle config set --local without docgen chefstyle development test
bundle install --jobs=2 --retry=3 --without docgen chefstyle development test

echo "Running post-bundle-install.rb.."
ruby post-bundle-install.rb

echo "Building gems.."
rake install:local
gem build chef.gemspec

echo "Push gems to artifactory.."
ruby .expeditor/scripts/chef_gem_publish.rb
