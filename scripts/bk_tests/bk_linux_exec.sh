#!/bin/bash

# Enable IPv6 in docker
echo "--- Enabling ipv6 on docker"
sudo systemctl stop docker
dockerd_config="/etc/docker/daemon.json"
sudo echo "$(jq '. + {"ipv6": true, "fixed-cidr-v6": "2001:2019:6002::/80", "ip-forward": false}' $dockerd_config)" > $dockerd_config
sudo systemctl start docker

# Install C and C++
echo "--- Installing package deps"
sudo yum install -y gcc gcc-c++ openssl-devel readline-devel zlib-devel

# Install omnibus-toolchain for git bundler and gem
echo "--- Installing omnibus toolchain"
curl -fsSL https://chef.io/chef/install.sh | sudo bash -s -- -P omnibus-toolchain

# Set Environment Variables
export BUNDLE_GEMFILE=$PWD/kitchen-tests/Gemfile
export FORCE_FFI_YAJL=ext
export CHEF_LICENSE="accept-silent"
export PATH=$PATH:/opt/omnibus-toolchain/embedded/bin

# Update Gems
echo "--- Installing Gems"
echo 'gem: --no-document' >> ~/.gemrc
sudo iptables -L DOCKER || ( echo "DOCKER iptables chain missing" ; sudo iptables -N DOCKER )
/opt/omnibus-toolchain/bin/bundle install --jobs=3 --retry=3 --path=../vendor/bundle

echo "--- Config information"

echo "!!!! RUBY VERSION !!!!"
ruby --version
echo "!!!! BUNDLE LOCATION !!!!"
which bundle
echo "!!!! DOCKER VERSION !!!!"
docker version
echo "!!!! DOCKER STATUS !!!!"
sudo service docker status

echo "+++ Running tests"