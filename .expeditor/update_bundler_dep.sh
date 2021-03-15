#!/bin/bash

############################################################################
# What is this script?
#
# Chef uses a workflow tool called Expeditor to manage version bumps, changelogs
# and releases. When a dependency of chef is released, expeditor is triggered
# against this repository to run this script. It bumps our gem lock files and opens
# a PR. That way humans can do hard work and bots can open gem bump PRs.
############################################################################

set -evx

branch="expeditor/${EXPEDITOR_REPO}_${EXPEDITOR_LATEST_COMMIT}"
git checkout -b "$branch"

bundle lock --update

git add .

# give a friendly message for the commit and make sure it's noted for any future audit of our codebase that no
# DCO sign-off is needed for this sort of PR since it contains no intellectual property
git commit --message "Bump $EXPEDITOR_REPO to $EXPEDITOR_LATEST_COMMIT" --message "This pull request was triggered automatically via Expeditor when $DEPNAME $EXPEDITOR_LATEST_COMMIT was merged." --message "This change falls under the obvious fix policy so no Developer Certificate of Origin (DCO) sign-off is required."

open_pull_request "$EXPEDITOR_BRANCH"

# Get back to master and cleanup the leftovers - any changed files left over at the end of this script will get committed to master.
git checkout -
git branch -D "$branch"
