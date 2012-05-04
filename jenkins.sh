#!/bin/bash
#
# Build you some jenkins
#

set -e

if [ $CLEAN = "true" ]; then
  rm -rf /opt/chef || true
  mkdir -p /opt/chef && chown jenkins /opt/chef
  rm -rf /opt/chef-server || true
  mkdir -p /opt/chef-server && chown jenkins /opt/chef
  rm -r /var/cache/omnibus/pkg/* || true
  rm pkg/* || true 
  bundle update
else
  bundle install
fi

# Omnibus build server prep tasks, including build ruby 
sudo env OMNIBUS_GEM_PATH=$(bundle show omnibus) chef-solo -c jenkins-solo.rb -j jenkins-dna.json -l debug

# Aaand.. new ruby
export PATH=/usr/local/bin:$PATH
if [ $CLEAN = "true" ]; then
  bundle update
else
  bundle install
fi 

rake projects:$1

