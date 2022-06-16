#!/bin/sh

############################################################################
# What is this script?
#
# Chef uses a workflow tool called Expeditor to manage version bumps, changelogs
# and releases. After a PR is merged in Chef Expeditor calls this script to update
# the PATCH version in the VERSION file as well as the version.rb file in both chef
# and chef-config. When that's done it bundle updates to pull in that new chef-config.
############################################################################

set -evx

VERSION=$(cat VERSION)
ORIGINAL_VERSION=$(git show main:VERSION)

sed -i -r "s/^(\s*)VERSION = \".+\"/\1VERSION = \"${VERSION}\"/" chef-config/lib/chef-config/version.rb
sed -i -r "s/^(\s*)VERSION = \".+\"/\1VERSION = \"${VERSION}\"/" chef-bin/lib/chef-bin/version.rb
sed -i -r "s/^(\s*)VERSION = \".+\"/\1VERSION = \"${VERSION}\"/" chef-utils/lib/chef-utils/version.rb
sed -i -r "s/^(\s*)VERSION = \".+\"/\1VERSION = \"${VERSION}\"/" knife/lib/chef/knife/version.rb
sed -i -r "s/VersionString\.new\(\".+\"\)/VersionString.new(\"${VERSION}\")/" lib/chef/version.rb

# Update the version inside Gemfile.lock
sed -i -r "s/(^\s+chef\s+.+)${ORIGINAL_VERSION}(.+)/\1${VERSION}\2/" Gemfile.lock
sed -i -r "s/(^\s+chef-bin\s+.+)${ORIGINAL_VERSION}(.+)/\1${VERSION}\2/" Gemfile.lock
sed -i -r "s/(^\s+chef-config\s+.+)${ORIGINAL_VERSION}(.+)/\1${VERSION}\2/" Gemfile.lock
sed -i -r "s/(^\s+chef-utils\s+.+)${ORIGINAL_VERSION}(.+)/\1${VERSION}\2/" Gemfile.lock

# Once Expeditor finishes executing this script, it will commit the changes and push
# the commit as a new tag corresponding to the value in the VERSION file.
