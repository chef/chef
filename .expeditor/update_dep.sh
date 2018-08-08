#!/bin/sh

set -evx

branch="expeditor/${GEM_NAME}_${VERSION}"
git checkout -b "$branch"

bundle update $GEM_NAME -v $VERSION

git add .
git commit --message "Bump $GEM_NAME to $VERSION" --message "This pull request was triggered automatically via Expeditor when $GEM_NAME $VERSION was promoted to Rubygems."

open_pull_request

# Get back to master and cleanup the leftovers - any changed files left over at the end of this script will get committed to master.
git checkout -
git branch -D "$branch"
