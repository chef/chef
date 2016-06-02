#!/bin/sh

set -evx

gem environment
bundler_version=$(grep bundler omnibus_overrides.rb | cut -d'"' -f2)
gem install bundler -v $bundler_version --user-install
bundle _${bundler_version}_ install
