#!/bin/bash
#
# Test you some omnibus client
#

set -e
set -x

# TODO:
# In the future, test-specific boxes will slurp up the artifacts
# (package and source) and build the test scenario from scratch.
# For now, we will run tests immediately after the build, so we know
# where everything is located.

cd /var/cache/omnibus/src/chef/chef
mkdir bundle

export PATH=/opt/chef/bin:/opt/chef/emebedded/bin:$PATH
bundle install --without server --path bundle
bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o $WORKSPACE/test.xml -f documentation spec
