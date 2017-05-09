#!/bin/sh

# FIXME: this seems uselessly trivial, replace with a rake task and have ci call the rake task?

set -evx

. ci/bundle_install.sh

bundle exec rake dependencies_ci
