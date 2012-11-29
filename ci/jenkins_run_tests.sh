#!/bin/bash

export PATH=/usr/local/bin:$PATH

# Chef 10 contains the client in the chef/ sub-directory
cd chef

ruby -v;
# remove the Gemfile.lock and try again if bundler fails.
# This should take care of Gemfile changes that result in "bad" bundles without forcing us to rebundle every time
bundle install --binstubs --path vendor/bundle || ( rm Gemfile.lock && bundle install --binstubs --path vendor/bundle )
bin/rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec;
RSPEC_RETURNCODE=$?

# move the rspec results back into the jenkins working directory
mv test.xml ..

# exit with the result of running rspec
return $RSPEC_RETURNCODE
