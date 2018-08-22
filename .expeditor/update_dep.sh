#!/bin/bash

set -evx

branch="expeditor/${GEM_NAME}_${VERSION}"
git checkout -b "$branch"

bundle install
bundle exec rake dependencies:update

git add .
git commit --message "Bump $GEM_NAME to $VERSION" --message "This pull request was triggered automatically via Expeditor when $GEM_NAME $VERSION was promoted to Rubygems." --message "Obvious fix - no DCO required"

open_pull_request

# Get back to master and cleanup the leftovers - any changed files left over at the end of this script will get committed to master.
git checkout -
git branch -D "$branch"
