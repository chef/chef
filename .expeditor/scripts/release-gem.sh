#!/bin/bash
set -eou pipefail

 sudo yum update -y
sudo yum install gcc
 gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source /home/ec2-user/.rvm/scripts/rvm
rvm install 3.2
ruby --version
 gem install bundler --no-document
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
