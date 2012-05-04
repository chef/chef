#!/bin/bash
#
# Build you some jenkins
#

bundle install
omnibus_path = $(bundle show omnibus)
chef-solo -c jenkins-solo.rb -j jenkins-dna.json
