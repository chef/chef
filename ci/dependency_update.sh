#!/bin/sh

# FIXME: this seems uselessly trivial, replace with a rake task and have ci call the rake task?

set -evx

bundle install --without omnibus_package test pry integration docgen maintenance travis aix bsd linux mac_os_x solaris windows development

bundle exec rake dependencies_ci
