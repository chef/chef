#!/bin/sh

set -evx

gem environment
bundler_version=$(grep bundler omnibus_overrides.rb | cut -d'"' -f2)
gem install bundler -v $bundler_version --user-install --conservative
# WITH: ci (for version bumping and changelog creation)
export BUNDLE_WITHOUT=omnibus_package:test:pry:integration:docgen:maintenance:travis:aix:bsd:linux:mac_os_x:solaris:windows:development:travis
bundle _${bundler_version}_ install
