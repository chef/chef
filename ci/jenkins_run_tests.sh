#!/bin/bash

export PATH=/usr/local/bin:$PATH

ruby -v;
# remove the Gemfile.lock and try again if bundler fails.
# This should take care of Gemfile changes that result in "bad" bundles without forcing us to rebundle every time
bundle install --binstubs --path vendor/bundle || ( rm Gemfile.lock && bundle install --binstubs --path vendor/bundle )
bin/rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec;
