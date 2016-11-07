#!/bin/sh

set -evx

. ci/bundle_install.sh

bundle exec rake version:bump
bundle exec rake changelog:update

git checkout .bundle/config
