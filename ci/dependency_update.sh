#!/bin/sh

set -evx

. ci/bundle_install.sh

bundle exec rake dependencies

git checkout .bundle/config
