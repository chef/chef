#!/bin/sh

set -evx

gem environment
bundler_version=$(grep bundler omnibus_overrides.rb | cut -d'"' -f2)
gem install bundler -v $bundler_version --user-install --conservative
export BUNDLE_WITHOUT=default:omnibus_package:test:pry:integration:docgen:maintenance:changelog:travis:aix:bsd:linux:mac_os_x:solaris:windows
bundle _${bundler_version}_ install
