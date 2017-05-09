#!/bin/sh
# FIXME: someone document what actually calls this
# FIXME: is this really the best place for this or should it go in the rake tasks?

set -evx

gem environment
omnibus_bundler=$(grep bundler omnibus_overrides.rb | cut -d'"' -f2)
gem uninstall bundler -a -x
gem install bundler -v $omnibus_bundler --user-install --conservative
# WITH: ci (for version bumping and changelog creation)
bundle install --without omnibus_package test pry integration docgen maintenance travis aix bsd linux mac_os_x solaris windows development
