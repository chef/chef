# Chef
[![Code Climate](https://codeclimate.com/github/chef/chef.svg)](https://codeclimate.com/github/chef/chef)
[![Build Status Master](https://travis-ci.org/chef/chef.svg?branch=master)](https://travis-ci.org/chef/chef)
[![Build Status Master](https://ci.appveyor.com/api/projects/status/github/chef/chef?branch=master&svg=true&passingText=master%20-%20Ok&pendingText=master%20-%20Pending&failingText=master%20-%20Failing)](https://ci.appveyor.com/project/Chef/chef/branch/master)
[![Gem Version](https://badge.fury.io/rb/chef.svg)](https://badge.fury.io/rb/chef)
[![](https://img.shields.io/badge/Release%20Policy-Cadence%20Release-brightgreen.svg)](https://github.com/chef/chef-rfc/blob/master/rfc086-chef-oss-project-policies.md#cadence-release)

## Getting Started

Want to try Chef?
For Chef user, please refer to [Quick Start](https://docs.chef.io/quick_start.html)
For more details, please refer to [learnchef](https://learn.chef.io)

- Documentation: <https://docs.chef.io>
- Source: <https://github.com/chef/chef/tree/master>
- Tickets/Issues: <https://github.com/chef/chef/issues>
- Slack: [Chef Community Slack](https://community-slack.chef.io/)
- Mailing list: <https://discourse.chef.io>

Chef is a configuration management tool designed to bring automation to your
entire infrastructure.

This README focuses on developers who want to modify Chef source code.
If you just want to use Chef, check out these resources:

- [learnchef](https://learn.chef.io): Getting started guide
- [docs.chef.io](https://docs.chef.io): Comprehensive User Docs
- [Installer Downloads](https://downloads.chef.io/chef/): Install Chef as a complete package
- [chef/chef](https://hub.docker.com/r/chef/chef): Docker image for use with [kitchen-dokken](https://github.com/someara/kitchen-dokken)

## Reporting Issues

Issues can be reported by using [GitHub Issues](https://github.com/chef/chef/issues).

Full details on how to report issues can be found in the [CONTRIBUTING](https://github.com/chef/chef/blob/master/CONTRIBUTING.md#-chef-issue-tracking) doc.

Note that this repository is primarily for reporting chef-client issues.
For reporting issues against other Chef projects, please look up the appropriate repository
to report issues against in the Chef docs in the
[community contributions section](https://docs.chef.io/community_contributions.html#issues-and-bug-reports).
If you can't determine the appropriate place to report an issue, then please open it
against the repository you think best fits and it will be directed to the appropriate project.

## Installing From Git for Developers

**NOTE:** As a Chef user, please download the omnibus package of [Chef](https://downloads.chef.io/chef) or [Chef-DK](https://downloads.chef.io/chef)

We do not recommend installing from gems, or building from source.  The following instructions apply only to those doing software development on Chef.

### Prerequisites

Install:

* git
* C compiler, header files, etc.
* ruby 2.3.3 or later
* rubygems
* bundler gem

We support too many platforms, and there are too many different ways to manage ruby installs, so
it is assumed the user understands how to accomplish this for their platform and needs (see previous
note about downloading the pre-built omnibus install if you do not understand how to accomplish this).

### Chef Installation

Then get the source and install it:

```bash
git clone https://github.com/chef/chef.git
cd chef
bundle install
bundle exec rake gem
bundle exec rake install
```

## Contributing/Development

Please read our [Community Contributions Guidelines](https://docs.chef.io/community_contributions.html), and
ensure you are signing all your commits with DCO sign-off.

The general development process is:

1. Fork this repo and clone it to your workstation.
2. Create a feature branch for your change.
3. Write code and tests.
4. Push your feature branch to github and open a pull request against master.

Once your repository is set up, you can start working on the code. We do utilize
RSpec for test driven development, so you'll need to get a development
environment running. Follow the above procedure ("Installing from Git") to get
your local copy of the source running.

## Testing

This repository only uses rspec for testing.

```bash
# all tests
bundle exec rspec

# single test
bundle exec rspec spec/PATH/TO/FILE_spec.rb

# all tests under a subdir
bundle exec rspec spec/PATH/TO/DIR
```

When you submit a PR rspec tests will run automatically on travis and appveyor.

## Building the Full Package

To build chef as a standalone package, we use the [omnibus](omnibus/README.md) system.

To build:

```bash
git clone https://github.com/chef/chef.git
cd chef/omnibus
bundle install
bundle exec omnibus build chef
```

The prerequisites necessary to run omnibus itself are not documented here.  The automation we use is
the [opscode-ci cookbook](https://github.com/chef-cookbooks/opscode-ci) cookbook, which serves as the most
current documentation.

## Updating Dependencies

If you want to change our constraints (change which packages and versions we accept in the chef), there are several places to do so:

* [Gemfile](Gemfile) and [Gemfile.lock](Gemfile.lock):  All gem version constraints (update with `bundle update`)
* [omnibus_overrides.rb](omnibus_overrides_rb):  Pinned versions of omnibus packages.
* [omnibus/Gemfile](omnibus/Gemfile) and [omnibus/Gemfile.lock](omnibus/Gemfile.lock):  Gems for the omnibus build system itself.

In addition there are several places versions are pinned for CI tasks:

* [acceptance/Gemfile](acceptance/Gemfile) and [acceptance/Gemfile.lock](acceptance/Gemfile.lock):  Acceptance tests (internal jenkins)
* [kitchen-tests/Gemfile](kitchen-tests/Gemfile) and [kitchen-tests/Gemfile.lock](kitchen-tests/Gemfile.lock): Gems for test-kitchen tests (travis)
* [kitchen-tests/Berksfile](kitchen-tests/Berksfile) and [kitchen-tests/Berksfile.lock](kitchen-tests/Berksfile.lock): Cookbooks for test-kitchen tests (travis)

In order to update everything run `rake dependencies`.  Note that the [Gemfile.lock](Gemfile.lock) pins windows platforms and to fully regenerate the lockfile
you must use the following commands or run `rake dependencies:update_gemfile_lock`:

```bash
bundle lock --update --add-platform ruby
bundle lock --update --add-platform x64-mingw32
bundle lock --update --add-platform x86-mingw32
```

# How Chef Builds and Versions

Chef is an amalgam of many components. These components update all the time, necessitating new builds. This is an overview of the process of versioning, building and releasing Chef.

## Chef Packages

Chef is distributed as packages for debian, rhel, ubuntu, windows, solaris, aix, and os x. It includes a large number of components from various sources, and these are versioned and maintained separately from chef project, which bundles them all together conveniently for the user.

These packages go through several milestones:
- `master`: When code is checked in to master, the patch version of chef is bumped (e.g. 0.9.10 -> 0.9.11) and a build is kicked off automatically to create and test the packages in Chef's Jenkins cluster.
- `unstable`: When a package is built, it enters the unstable channel. When all packages for all OS's have successfully built, the test phase is kicked off in Jenkins across all supported OS's. These builds are password-protected and generally only available to the test systems.
- `current`: If the packages pass all the tests on all supported OS's, it is promoted as a unit to `current`, and is available via Chef's artifactory by running `curl https://www.chef.io/chef/install.sh | sudo bash -s -- -c current -P chef`
- `stable`: Periodically, Chef will pick a release to "bless" for folks who would like a slower update schedule than "every time a build passes the tests." When this happens, it is manually promoted to stable and an announcement is sent to the list. It can be reached at https://downloads.chef.io or installed using the `curl` command without specifying `-c current`. Packages in `stable` are no longer available in `current`.

Additionally, periodically Chef will update the desired versions of chef components and check that in to `master`, triggering a new build with the updated components in it.

## Automated Version Bumping

Whenever a change is checked in to `master`, the patch version of `chef` is bumped. To do this, the `lita-versioner` bot listens to github for merged PRs, and when it finds one, takes these actions:

1. Bumps the patch version in `lib/chef/version.rb` (e.g. 0.9.14 -> 0.9.15).
2. Runs `rake bundle:install` to update the `Gemfile.lock` to include the new version.
3. Runs `rake changelog:update` to update the `CHANGELOG.md`.
4. Pushes to `master` and submits a new build to Chef's Jenkins cluster.

## Bumping the minor version of Chef

After each "official" stable release we need to bump the minor version. To do this:

1. Run `bundle exec rake version:bump_minor`

Submit a PR with the changes made by the above.

## Addressing a Regression

Sometimes, regressions split through the cracks. Since new functionality is always being added and the minor version is bumped immediately after release, we can't simply roll forward. In this scenario, we'll need to perform a special regression release process. In the example that follows, the stable release with a regression is `1.10.60` while master is currently sitting at `1.11.30`. *Note:* To perform this process, you must be a Chef employee.

1. If the regression has not already been addressed, open a Pull Request against master with the fix.
2. Wait until that Pull Request has been merged and `1.11.31` has passed all the necessary tests and is available in the current channel.
3. Inspect the Git history and find the `SHA` associated with the Merge Commit for the Pull Request above.
4. Apply the fix for the regression via a cherry-pick:
  1. Check out the stable release tag: `git checkout v1.10.60`
  2. Cherry Pick the SHA with the fix: `git cherry-pick SHA`
  3. Address any conflicts (if necessary)
  4. Tag the sha with the appropriate version: `git tag -a v1.10.61 -m "Release v1.10.61"`
  5. Push the new tag to origin: `git push origin --tags`
5. Log in to Jenkins and trigger a `chef-trigger-release` job specifying the new tag as the `GIT_REF`.

## Component Versions

Chef has two sorts of component: ruby components like `berkshelf` and `test-kitchen`, and binary components like `openssl` and even `ruby` itself.

In general, you can find all chef desired versions in the [Gemfile](Gemfile) and [omnibus_overrides.rb](omnibus_overrides.rb) files. The [Gemfile.lock](Gemfile.lock) is the locked version of the Gemfile.

### Binary Components

The versions of binary components (as well as rubygems and bundler, which can't be versioned in a Gemfile) are stored in [omnibus_overrides.rb](omnibus_overrides.rb).

These have software definitions either in [omnibus/config/software](omnibus/config/software) or, more often, in the [omnibus-software](https://github.com/chef/omnibus-software/tree/master/config/software) project.

### Rubygems Components

Our rubygems component versions are locked down with `Gemfile.lock`, and can be updated with `bundle update` or `rake dependencies:update_gemfile_lock`.

### Build Tooling Versions

The external environment necessary to build omnibus (compilers, make, git, etc) is configured by the [opscode-ci cookbook](https://github.com/chef-cookbooks/opscode-ci) cookbook.  In order to reliably create omnibus builds that cookbook should be used to install the prerequisites.  It may be possible to install the latest version
of utilities on a suitably recent distribution and be able to build an omnibus package, but the necessary prerequisites will not be documented here.  In most
cases a recent MacOS with Xcode and a few homebrew packages or a recent Ubuntu distribution with packages like `build-essentials` should suffice.

### Test Versions

chef is tested by the [chef-acceptance framework](https://github.com/chef/chef-acceptance), which contains suites that are run on the Jenkins test machines. The definitions of the tests are in the `acceptance` directory. The version of chef-acceptance and test-kitchen, are governed by `acceptance/Gemfile`.

The test tooling versions are locked down with `acceptance/Gemfile.lock`, which can be updated by running `rake dependencies`.

# License

Chef - A configuration management system

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Adam Jacob (<adam@chef.io>)
| **Copyright:**       | Copyright 2008-2016, Chef Software, Inc.
| **License:**         | Apache License, Version 2.0

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
