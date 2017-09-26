#!/bin/sh
#
# After a PR merge, Chef Expeditor will bump the PATCH version in the VERSION file.
# It then executes this file to update any other files/components with that new version.
#

set -evx

sed -i -r "s/^(\s*)VERSION = \".+\"/\1VERSION = \"$(cat VERSION)\"/" chef-config/lib/chef-config/version.rb
sed -i -r "s/VersionString\.new\(\".+\"\)/VersionString.new(\"$(cat VERSION)\")/" lib/chef/version.rb

# Update the version inside Gemfile.lock
bundle update chef chef-config

# Once Expeditor finshes executing this script, it will commit the changes and push
# the commit as a new tag corresponding to the value in the VERSION file.
