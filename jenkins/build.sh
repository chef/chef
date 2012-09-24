#!/bin/bash
#
# Build you some jenkins
#

set -e
set -x

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists()
{
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
  fi
}


mkdir -p chef-solo/cache

if [ "$CLEAN" = "true" ]; then
  sudo rm -rf /opt/$1 || true
  sudo mkdir -p /opt/$1 && sudo chown jenkins-node /opt/$1
  sudo rm -r /var/cache/omnibus/pkg/* || true
  sudo rm /var/cache/omnibus/build/*/*.manifest || true
  sudo rm pkg/* || true
  bundle update
else
  bundle install
fi

# Omnibus build server prep tasks, including build ruby
sudo env OMNIBUS_GEM_PATH=$(bundle show omnibus) chef-solo -c jenkins-solo.rb -j jenkins-dna.json -l debug

# copy config into place
cp omnibus.rb.example omnibus.rb

# Aaand.. new ruby
export PATH=/usr/local/bin:$PATH
if [ "$CLEAN" = "true" ]; then
  bundle update
else
  bundle install
fi

rake projects:$1

# Sign the package on some platforms:
if exists rpm;
then
  sudo -i $(pwd)/jenkins/sign-rpm "foo" $(pwd)/pkg/*rpm
fi
