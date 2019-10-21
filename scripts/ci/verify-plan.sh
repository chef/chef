#!/bin/bash
#
# "Verify" according to the meaning given in delivery/workflow pipelines,
# i.e. pre-build, pre-publish testing. Despite the fact that this verify
# script performs a build of the Habitat package, it does so only to test
# that the plan's code produces a useable build, not to create a publishable
# artifact.
#

set -eou pipefail

echo "--- :8ball: :linux: Verifying chef-infra-client"

HAB_LICENSE="accept-no-persist"
export HAB_LICENSE

echo "--- :key: Generating fake origin key for test build"
# This is intended to be run in the context of public CI where
# we won't have access to any valid signing keys.
HAB_ORIGIN=ci
export HAB_ORIGIN
hab origin key generate "${HAB_ORIGIN}"


echo "--- :construction: Starting build"
# We'll build from the root of the project's git repo. To do that,
# we'll need to ensure git is installed to determine the
# project root directory.
if type git 2>/dev/null; then
  echo "--- :thumbsup: git's installed"
else
  echo "--- :hammer_and_wrench: installing git"
  hab pkg install core/git --binlink
fi
project_root="$(git rev-parse --show-toplevel)"

# Ensure that we build the chef-client Habitat package from the
# project root. Change directory in a subshell to return to current working
# directory when build is done.
( cd "$project_root" || exit 1

  echo "--- :construction: :linux: Building"
  env DO_CHECK=true hab pkg build .
)

source $project_root/results/last_build.env # reference metadata from the build

## TODO: if in CI env, upload public key and built package to buildkite job
# buildkite-agent artifact upload /hab/cache/keys/${HAB_ORIGIN}-*.pub
# buildkite-agent artifact upload results/${pkg_artifact}


( cd "$project_root" || exit 1

  echo "--- :mag_right: :linux: Testing"
  echo "... installing what we built"
  hab pkg install results/${pkg_artifact}
  echo "... testing what we built"
  ./habitat/tests/test.sh ${pkg_ident}
)
