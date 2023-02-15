#!/bin/bash

if [ -d "/opt/chef" ]; then
  echo "Chef client installation directory exists."
else
  echo "Chef client installation directory does not exist."
  exit 1
fi

echo "--- Ensure 'chef-client' command works"
/opt/chef/bin/chef-client --version

FORK_OWNER="chef"
REPO_NAME="chef.git"
#TAG_NAME="v18.0.185"
TAG_NAME="v${EXPEDITOR_VERSION}"
echo "--- Getting $FORK_OWNER/$REPO_NAME repository cloning ---"
# git clone -b [tag_name] [repository_url]
git clone -b  $TAG_NAME https://github.com/$FORK_OWNER/$REPO_NAME

cd chef
#source ../chef/omnibus/omnibus-test.sh
#exec "$@"
