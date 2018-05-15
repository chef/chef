#!/bin/sh

# FIXME: this seems uselessly trivial, replace with a rake task and have ci call the rake task?

set -evx

export LANG=en_US.UTF-8

bundle install --without omnibus_package test pry integration docgen maintenance travis aix bsd linux mac_os_x solaris windows development

bundle exec rake ci_version_bump
