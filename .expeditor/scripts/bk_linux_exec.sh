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

# Install ASDF
echo "--- Installing asdf to ${HOME}/.asdf"
git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf"
cd "${HOME}/.asdf"; git checkout "$(git describe --abbrev=0 --tags)"; cd -
. "${HOME}/.asdf/asdf.sh"

# Install Ruby
ruby_version=$(sed -n '/"ruby"/{s/.*version: "//;s/"//;p;}' omnibus_overrides.rb)
echo "--- Installing Ruby $ruby_version"
asdf plugin add ruby
asdf install ruby $ruby_version
asdf global ruby $ruby_version

# Set Environment Variables
export BUNDLE_GEMFILE=$PWD/kitchen-tests/Gemfile
export FORCE_FFI_YAJL=ext
export CHEF_LICENSE="accept-silent"

# Update Gems
echo "--- Installing Gems"
echo 'gem: --no-document' >> ~/.gemrc
sudo iptables -L DOCKER || ( echo "DOCKER iptables chain missing" ; sudo iptables -N DOCKER )
bundle install --jobs=3 --retry=3 --path=../vendor/bundle

echo "--- Config information"

echo "!!!! RUBY VERSION !!!!"
ruby --version
echo "!!!! BUNDLER LOCATION !!!!"
which bundle
echo "!!!! BUNDLER VERSION !!!!"
bundle -v
echo "!!!! DOCKER VERSION !!!!"
docker version
echo "!!!! DOCKER STATUS !!!!"
sudo service docker status

echo "+++ Running tests"
