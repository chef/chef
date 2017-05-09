#!/bin/sh

# FIXME: this seems uselessly trivial, replace with a rake task and have ci call the rake task?

set -evx

export LANG=en_US.UTF-8

. ci/bundle_install.sh

bundle exec rake ci_version_bump
