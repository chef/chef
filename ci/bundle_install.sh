#!/bin/sh

set -evx

bundler_version=$(grep bundler omnibus_overrides.rb | cut -d'"' -f2)
gem install bundler -v $bundler_version
bundle _${bundler_version}_ install
