#!/bin/sh

# Check runit installation
docker run $1 test -f /opt/chef/embedded/bin/sv
if [ $? -ne 0 ]; then
  echo "/opt/chef/embedded/bin/sv was not found"
  exit 1
fi

# Check chef-client installation
docker run $1 chef-client --version
if [ $? -ne 0 ]; then
  echo "chef-client was not found"
  exit 1
fi

# Check chef-init installation
docker run $1 chef-init --version
if [ $? -ne 0 ]; then
  echo "chef-init was not found"
  exit 1
fi
