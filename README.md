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
- [chef/chef](https://hub.docker.com/r/chef/chef/): Docker image for use with [kitchen-dokken](https://github.com/someara/kitchen-dokken/)

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

**NOTE:** As a Chef user, please download the [Chef](https://downloads.chef.io/chef) or [Chef-DK](https://downloads.chef.io/chef) packages, which provide Ruby and other necessary libraries for running Chef.

We do not recommend end users install Chef from gems or build from source. The following instructions apply only to those doing software development on Chef.

### Prerequisites

Install:

- git
- C compiler, header files, etc.
- Ruby 2.4 or later
- bundler gem

**NOTE:** Chef supports a large number of platforms, and there are many different ways to manage Ruby installs on each of those platforms. We assume you will install Ruby in a way appropriate for your development platform, but do not provide instructions for setting up Ruby.

### Chef Installation

Once you have your development environment configured you can clone the Chef repository and install Chef:

```bash
git clone https://github.com/chef/chef.git
cd chef
bundle install
bundle exec rake install
```

## Contributing/Development

Please read our [Community Contributions Guidelines](https://docs.chef.io/community_contributions.html), and ensure you are signing all your commits with DCO sign-off.

The general development process is:

1. Fork this repo and clone it to your workstation.
2. Create a feature branch for your change.
3. Write code and tests.
4. Push your feature branch to GitHub and open a pull request against master.

Once your repository is set up, you can start working on the code. We do utilize RSpec for test driven development, so you'll need to get a development environment running. Follow the above procedure ("Installing from Git") to get your local copy of the source running.

## Testing

This repository uses rspec for testing.

```bash
# all tests
bundle exec rspec

# single test
bundle exec rspec spec/PATH/TO/FILE_spec.rb

# all tests under a subdir
bundle exec rspec spec/PATH/TO/DIR
```

When you submit a PR rspec tests will run automatically on [Travis-CI](https://travis-ci.org/) and [AppVeyor](https://www.appveyor.com/).

## Building the Full Package

To build Chef as a standalone package, we use the [omnibus](omnibus/README.md) packaging system.

To build:

```bash
git clone https://github.com/chef/chef.git
cd chef/omnibus
bundle install
bundle exec omnibus build chef
```

The prerequisites necessary to run omnibus itself are not documented in this repository. See the [Omnibus repository](https://github.com/chef/omnibus) for additional details.

## Updating Dependencies

If you want to change our constraints (change which packages and versions we accept in the chef), there are several places to do so:

* [Gemfile](Gemfile) and [Gemfile.lock](Gemfile.lock):  All gem version constraints (update with `bundle update`)
* [omnibus_overrides.rb](omnibus_overrides_rb):  Pinned versions of omnibus packages.
* [omnibus/Gemfile](omnibus/Gemfile) and [omnibus/Gemfile.lock](omnibus/Gemfile.lock):  Gems for the omnibus build system itself.

In addition there are several places versions are pinned for CI tasks:

* [kitchen-tests/Gemfile](kitchen-tests/Gemfile) and [kitchen-tests/Gemfile.lock](kitchen-tests/Gemfile.lock): Gems for test-kitchen tests (travis)

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

Chef is distributed as packages for debian, rhel, ubuntu, windows, solaris, aix, and macos. It includes a large number of components from various sources, and these are versioned and maintained separately from the chef project, which bundles them all together conveniently for the user.

These packages go through several milestones:
- `master`: When code is checked in to master, the patch version of chef is bumped (e.g. 14.5.1 -> 14.5.2) and a build is kicked off automatically to create and test the packages in Chef's internal CI cluster.
- `unstable`: When a package is built, it enters the unstable channel. When all packages for all OS's have successfully built, the test phase is kicked off in Jenkins across all supported OS's. These builds are password-protected and generally only available to the test systems.
- `current`: If the packages pass all the tests on all supported OS's, it is promoted as a unit to `current`, and is available by running `curl https://www.chef.io/chef/install.sh | sudo bash -s -- -c current -P chef` or at <https://downloads.chef.io/chef/current>
- `stable`: Periodically, Chef will pick a release to "bless" for folks who would like a slower update schedule than "every time a build passes the tests." When this happens, it is manually promoted to stable and an announcement is sent to the list. It can be reached at <https://downloads.chef.io> or installed using the `curl` command without specifying `-c current`. Packages in `stable` are no longer available in `current`.

Additionally, periodically Chef will update the desired versions of chef components and check that in to `master`, triggering a new build with the updated components in it.

## Automated Version Bumping

Whenever a change is checked in to `master`, the patch version of `chef` is bumped. To do this, the `chef-ci` bot listens to GitHub for merged PRs, and when it finds one, takes these actions:

1. Bumps the patch version (e.g. 14.1.14 -> 14.1.15) by running ./ci/version_bump.sh
2. Updates the changelog with the new pull request and current point release
3. Pushes to `master` and submits a new build to Chef's Jenkins cluster.

## Bumping the minor version of Chef

After each "official" stable release we need to bump the minor version. To do this:

1. Run `bundle exec rake version:bump_minor`

Submit a PR with the changes made by the above.

## Branch Structure

We develop and ship the current release of Chef off the master branch of this repository. Our goal is that master should always be in a shipable state. Previous stable releases of Chef are developed on their own branches named by the major version (ex: chef-13 or chef-12). We do not perform direct development on these stable branches except to resolve build failures. Instead we backport fixes from our master branch to these stable branches. Stable branches receive critical bugfixes and security releases and stable Chef releases are made as necessary for security purposes.

## Backporting Fixes to Stable Releases

If there is a critical fix you believe should be backported from master to a stable branch please follow these steps to backport your change:

1. Ask in the #chef-dev channel on [Chef Community Slack](https://community-slack.chef.io/) if this is an appropriate change to backport.
3. Inspect the Git history and find the `SHA`(s) associated with the fix.
4. Backport the fix to a branch via cherry-pick:
  1. Check out the stable release branch: `git checkout chef-13`
  1. Create a branch for your backport: `git checkout -b my_great_bug_packport`
  2. Cherry Pick the SHA with the fix: `git cherry-pick SHA`
  3. Address any conflicts (if necessary)
  5. Push the new branch to your origin: `git push origin`
5. Open a PR for your backport
  1. The PR title should be `Backport: ORIGINAL_PR_TEXT`
  2. The description should link to the original PR and include a description of why it needs to be backported

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
| **Copyright:**       | Copyright 2008-2018, Chef Software, Inc.
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
