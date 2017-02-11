#!/bin/sh

set -evx

export LANG=en_US.UTF-8

. ci/bundle_install.sh

bundle exec rake ci_version_bump

git checkout .bundle/config
