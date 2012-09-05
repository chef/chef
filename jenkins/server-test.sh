#!/bin/bash

set -e
set -x

echo "Attempting to remove chef-server, forcing success in case it's not installed"

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists() {
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
  fi
}

if exists dpkg;
then
  sudo dpkg -P chef-server || true
  sudo jenkins/server-killer.sh
  sudo dpkg -i pkg/chef-server*deb
else
  sudo rpm -ev chef-server  || true
  sudo jenkins/server-killer.sh
  sudo rpm -Uvh pkg/chef-server*rpm
fi

export PATH=/opt/chef-server/bin:/opt/chef-server/embedded/bin:$PATH
sudo chef-server-ctl reconfigure
sleep 120
sudo chef-server-ctl test -J $WORKSPACE/pedant.xml
# when build succeeds, nuke the packages
find . -type d -maxdepth 1 -mindepth 1 | xargs rm -rf
