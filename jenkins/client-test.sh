#!/bin/bash
#
# Test you some omnibus client
#
set -e
set -x

# install the chef package
# TODO: here
export PATH=/opt/chef/bin:/opt/chef/embedded/bin:$PATH

# extract the chef source code
tar xvzf pkg/chef*.tar.gz

# install all of the development gems
cd chef/chef
mkdir bundle
bundle install --without server --path bundle

# run the tests
sudo env PATH=$PATH bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o $WORKSPACE/test.xml -f documentation spec
