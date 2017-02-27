#!/bin/sh

set -evx

. ci/bundle_install.sh

bundle exec rake dependencies_ci

git checkout .bundle/config
