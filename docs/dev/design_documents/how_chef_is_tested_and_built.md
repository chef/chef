# How Chef Infra Client is Tested and Built

This document describes the process that a change flows through from opened PR to omnibus build in our current channel.

## User Opens Pull Request

Here's where all the magic begins. You have a great idea, so you decide to contribute. You fork the chef repository, make a change, and open a pull request in GitHub.

## Tests Validate the Pull request

We can't just merge any old change, so we run various checks against your submitted PR to make sure it's ready to review. We use GitHub's protected branches feature in the chef repo, so each of these checks must pass before a change can be approved:
  - **Expeditor Config**: At Chef, we use an internal tool named Expeditor to manage our overall release process, including bumping chef versions, adding changelog entries, kicking off CI/CD jobs, and promoting artifacts. It's important that we don't break this critical component of our release process, so each PR will be checked by Expeditor to make sure the config is valid. If anything doesn't pass, Expeditor will link you to remediation steps in the Expeditor docs.
  - **DCO sign-off**: Our Expeditor tool will check to make sure that every commit in your pull request has been signed off for the Developer Certificate of Origin (DCO). This gives us added legal protection above the Apache-2.0 license that we need to accept your contribution. Without this sign-off, we are unable to merge a PR.
  - **Buildkite**: Buildkite is where we run the majority of our publicly available tests.  Buildkite allows us to run tests in our own infrastructure while exposing the results to community members. We run 18 separate tests against each submitted PR. This includes the following tests:
    - Unit, functional, and integration tests on all supported Ruby releases. These run on Ubuntu, CentOS and openSUSE so we can make sure our functional / integration tests run on the platforms where user's consume Chef Infra.
    - Chefstyle Ruby linting
    - Unit tests from chef-sugar, chef-zero, cheffish, chefspec, and knife-windows against the chef code in your PR
  - **Travis**:
  We run full Test Kitchen integration tests that covers common Chef usage on various different Linux Distros in Travis-CI. Those integration tests run using the kitchen-dokken plugin and the dokken-images Docker containers, which do their best to replicate a real Linux system. You can see the exactly what we test here: https://github.com/chef/chef/blob/master/kitchen-tests/cookbooks/end_to_end/recipes/default.rb
  - **Appveyor**: Buildkite & Travis do a great job of testing PRs against Linux hosts, but many rspec tests require a Windows system to run, and for this, we test in Appveyor. In Appveyor, we run our unit, integration, and functional specs against our supported Ruby releases, but this time, we do it on Windows.

## PR is Reviewed and Merged

Once your pull request passes the above tests, it will need to be reviewed by at least two members of the Chef Infra project owners, approvers, or reviewers groups. For a list of owners, approvers, and reviewers, see https://github.com/chef/chef-oss-practices/blob/master/projects/chef-infra.md. GitHub will automatically assign these groups as reviewers. Reviews will happen adhoc as members in those groups have time, or during our weekly issue triage. Check the above team doc link for information on when that review takes place.

Your PR will be reviewed for Chef and Ruby correctness, overall design, and likelihood of impact on the community. We do our best to make sure all the changes made to Chef are high quality and easy to maintain going forward, while also having the lowest chance of negatively impacting our end users. If your PR meets that criteria, we'll merge the change into our master branch.

## Version Bump and Changelog Update

Every commit that we merge into Chef Infra should be ready to release. In order to ensure that's possible, each merged PR increments the patch version of the application and is noted in the changelog. This is performed automatically by our Expeditor tool. If you'd like to avoid one or both of these steps, there are Expeditor GitHub issue labels that can be applied to skip either.

## Jenkins Build / Test

Once the version has been incremented, Expeditor will begin a build matrix in our internal Jenkins CI cluster. In Jenkins, we build omnibus-based system packages of Chef Infra for multiple platforms, distros, and architectures. Each of the platforms we build are those which will eventually be available on our downloads site if this build is successful and later promoted. Upon completion, builds are promoted to the `unstable` channel and are available to any system supporting our Omnitruck API (Test Kitchen, mixlib-install, etc).

Once the builds complete, Jenkins will move to the test phase where each of these builds will be verified on all the platforms that Chef officially supports. For many build artifacts, this means the artifact tests on multiple versions of the same platform. For example, Chef is built on Windows 2012 R2, yet tests are run on 2008, 2012, 2012 R2, and 2016 to ensure full compatibility. In total, this phase includes nearly three dozen test nodes. Assuming all tests pass, the build will be promoted to the `current` channel, which is available on the downloads site, in addition to being available via the Omnitruck API.

## Releasing Chef

Once a build has been blessed by our Jenkins gauntlet and everyone has agreed that we are ready to release, an artifact can be promoted from current to stable channels. For the complete release process see [Releasing Chef Infra Client](../how_to/releasing_chef_infra.md)
