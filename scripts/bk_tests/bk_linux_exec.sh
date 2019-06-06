#!/bin/bash

# Enable IPv6 in docker
sudo systemctl stop docker
echo "Enabling IPv6 in Docker config"
dockerd_config="/etc/docker/daemon.json"
sudo echo "$(jq '. + {"ipv6": true, "fixed-cidr-v6": "2001:2019:6002::/80", "ip-forward": false}' $dockerd_config)" > $dockerd_config
sudo systemctl start docker

# Verify Docker Is Running
docker version
sudo service docker status

# Install C and C++
sudo yum install -y gcc gcc-c++ openssl-devel readline-devel zlib-devel

# Install omnibus-toolchain for git bundler and gem
curl -fsSL https://chef.io/chef/install.sh | sudo bash -s -- -P omnibus-toolchain

# Set Environment Variables
export BUNDLE_GEMFILE=$PWD/kitchen-tests/Gemfile
export FORCE_FFI_YAJL=ext
export CHEF_LICENSE="accept-silent"
export PATH=$PATH:~/.asdf/shims:/opt/asdf/bin:/opt/asdf/shims:/opt/omnibus-toolchain/embedded/bin

# Install ASDF software manager
echo "--- Installing ASDF software version manager from master"
sudo git clone https://github.com/asdf-vm/asdf.git /opt/asdf
. /opt/asdf/asdf.sh
. /opt/asdf/completions/asdf.bash

echo "--- Installing Ruby ASDF plugin"
/opt/asdf/bin/asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git 

echo "--- Installing Ruby 2.5.5"
/opt/asdf/bin/asdf install ruby 2.5.5
/opt/asdf/bin/asdf global ruby 2.5.5

# Update Gems
gem update --system $(grep rubygems omnibus_overrides.rb | cut -d'"' -f2)
gem install bundler -v $(grep :bundler omnibus_overrides.rb | cut -d'"' -f2) --force --no-document
sudo iptables -L DOCKER || ( echo "DOCKER iptables chain missing" ; sudo iptables -N DOCKER )
ruby --version
which bundle
bundle install --jobs=3 --retry=3 --path=vendor/bundle