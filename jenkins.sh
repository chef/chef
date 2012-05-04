#!/bin/bash
#
# Build you some jenkins
#

set -e

# First, we gotta install our own deps - this is using system ruby
bundle install

# Omnibus build server prep tasks, including build ruby 
sudo env OMNIBUS_GEM_PATH=$(bundle show omnibus) chef-solo -c jenkins-solo.rb -j jenkins-dna.json -l debug

# Aaand.. new ruby
export PATH=/usr/local/bin:$PATH
bundle install

rake projects:$1

