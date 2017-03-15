# Chef
[![Code Climate](https://codeclimate.com/github/chef/chef.svg)](https://codeclimate.com/github/chef/chef)
[![Build Status Master](https://travis-ci.org/chef/chef.svg?branch=master)](https://travis-ci.org/chef/chef)
[![Build Status Master](https://ci.appveyor.com/api/projects/status/github/chef/chef?branch=master&svg=true&passingText=master%20-%20Ok&pendingText=master%20-%20Pending&failingText=master%20-%20Failing)](https://ci.appveyor.com/project/Chef/chef/branch/master)
[![Gem Version](https://badge.fury.io/rb/chef.svg)](https://badge.fury.io/rb/chef)
[![](https://img.shields.io/badge/Release%20Policy-Cadence%20Release-brightgreen.svg)](https://github.com/chef/chef-rfc/blob/master/rfc086-chef-oss-project-policies.md#cadence-release)

Want to try Chef? Get started with [learnchef](https://learn.chef.io)

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

## Installing From Git

**NOTE:** Unless you have a specific reason to install from source (to
try a new feature, contribute a patch, or run chef on an OS for which no
package is available), you should head to the [downloads page](https://downloads.chef.io/chef/)
to get a prebuilt package.

### Prerequisites

Install these via your platform's preferred method (`apt`, `yum`, `ports`,
`emerge`, etc.):

* git
* C compiler, header files, etc. On Ubuntu/Debian, use the
  `build-essential` package.
* ruby 2.3.0 or later
* rubygems
* bundler gem

### Chef Installation

Then get the source and install it:

```bash
# Clone this repo
git clone https://github.com/chef/chef.git

# cd into the source tree
cd chef

# Install dependencies with bundler
bundle install

# Build a gem
bundle exec rake gem

# Install the gem you just built
gem install pkg/chef-VERSION.gem
```

## Contributing/Development

Before working on the code, if you plan to contribute your changes, you need to
read the
[Chef Contributions document](https://docs.chef.io/community_contributions.html).

The general development process is:

1. Fork this repo and clone it to your workstation.
2. Create a feature branch for your change.
3. Write code and tests.
4. Push your feature branch to github and open a pull request against master.

Once your repository is set up, you can start working on the code. We do utilize
RSpec for test driven development, so you'll need to get a development
environment running. Follow the above procedure ("Installing from Git") to get
your local copy of the source running.

## Reporting Issues

Issues can be reported by using [GitHub Issues](https://github.com/chef/chef/issues).

Full details on how to report issues can be found in the [CONTRIBUTING](https://github.com/chef/chef/blob/master/CONTRIBUTING.md#-chef-issue-tracking) doc.

Note that this repository is primarily for reporting chef-client issues.
For reporting issues against other Chef projects, please look up the appropriate repository
to report issues against in the Chef docs in the
[community contributions section](https://docs.chef.io/community_contributions.html#issues-and-bug-reports).
If you can't determine the appropriate place to report an issue, then please open it
against the repository you think best fits and it will be directed to the appropriate project.

## Testing

We use RSpec for unit/spec tests. It is not necessary to start the development
environment to run the specs--they are completely standalone.

```bash
# Run All the Tests
bundle exec rake spec

# Run a Single Test File
bundle exec rspec spec/PATH/TO/FILE_spec.rb

# Run a Subset of Tests
bundle exec rspec spec/PATH/TO/DIR
```

When you submit a pull request, we will automatically run the functional and unit
tests in spec/functional/ and spec/unit/ respectively. These will be run on Ubuntu
through Travis CI, and on Windows through AppVeyor. The status of these runs will
be displayed with your pull request.

## Building the Full Package

To build chef as a standalone package (with ruby and all dependent libraries included in a .deb, .rpm, .pkg or .msi), we use the omnibus system. Go to the [omnibus README](omnibus/README.md) to find out how to build!

## Updating Dependencies

If you want to change our constraints (change which packages and versions we accept in the chef), there are several places to do so:

* To add or remove a gem from chef, or update a gem version, edit [Gemfile](Gemfile).
* To change the version of binary packages, edit [version_policy.rb](version_policy.rb).
* To add new packages to chef, edit [omnibus/config/projects/chef.rb](omnibus/config/projects/chef.rb).

Once you've made any changes you want, you have to update the lockfiles that actually drive the build:
* To update chef's gem dependencies to the very latest versions available, run `rake bundle:update`.
* To update chef's gem dependencies *conservatively* (changing as little as possible), run `rake bundle:install`.
* To update specific gems only, run `rake bundle:update[gem1 gem2 ...]`
* **`bundle update` and `bundle install` will *not* work, on purpose:** the rake task handles both the windows and non-windows lockfiles and updates them in sync.

To perform a full update of all dependencies in chef (including binary packages, tests and build system dependencies), run `rake dependencies`. This will update the `Gemfile.lock`, `omnibus/Gemfile.lock`, `acceptance/Gemfile.lock`, `omnibus/Berksfile.lock`, and `omnibus_overrides.rb`.  It will also show you any outdated dependencies due to conflicting constraints. Some outdated dependencies are to be expected; it will inform you if any new ones appear that we don't know about, and tell you how to proceed.

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

In general, you can find all chef desired versions in the [Gemfile](Gemfile) and [version_policy.rb](version_policy.rb) files. The [Gemfile.lock](Gemfile.lock) is the locked version of the Gemfile, and [omnibus_overrides](omnibus_overrides.rb) is the locked version of omnibus. [build](omnibus/Gemfile) and [test](acceptance/Gemfile) Gemfiles and [Berksfile](omnibus/Berksfile) version the toolset we use to build and test.

### Binary Components

The versions of binary components (as well as rubygems and bundler, which can't be versioned in a Gemfile) are stored in [version_policy.rb](version_policy.rb) (the `OMNIBUS_OVERRIDES` constant) and locked in [omnibus_overrides](omnibus_overrides.rb).  `rake dependencies` will update the `bundler` version, and the rest are be updated manually by Chef every so often.

These have software definitions either in [omnibus/config/software](omnibus/config/software) or, more often, in the [omnibus-software](https://github.com/chef/omnibus-software/tree/master/config/software) project.

### Rubygems Components

Most of the actual front-facing software in chef is composed of ruby projects. berkshelf, test-kitchen and even chef itself are made of ruby gems. Chef uses the typical ruby way of controlling rubygems versions, the `Gemfile`. Specifically, the `Gemfile` at the top of chef repository governs the version of every single gem we install into chef package. It's a one-stop shop.

Our rubygems component versions are locked down with `Gemfile.lock`, and can be updated with `rake dependencies`.

There are three gems versioned outside the `Gemfile`: `rubygems`, `bundler` and `chef`. `rubygems` and `bundler` are in the `RUBYGEMS_AT_LATEST_VERSION` constant in [version_policy.rb](version-policy.rb) and locked in [omnibus_overrides](omnibus_overrides.rb). They are kept up to date by `rake dependencies`.

**Windows**: [Gemfile.lock](Gemfile.lock) is generated platform-agnostic, and then generated again for Windows. The one file has the solution for both Linux and Windows.

The tool we use to generate Windows-specific lockfiles on non-Windows machines is [tasks/bin/bundle-platform](bundle-platform), which takes the first argument and sets `Gem.platforms`, and then calls `bundle` with the remaining arguments.

### Build Tooling Versions

Of special mention is the software we use to build omnibus itself. There are two distinct bits of code that control the versions of compilers, make, git, and other tools we use to build.

First, the Jenkins machines that run the build are configured entirely by the [opscode-ci cookbook](https://github.com/chef-cookbooks/opscode-ci) cookbook. They install most of the tools we use via `build-essentials`, and standardize the build environment so we can tear down and bring up builders at will. These machines are kept alive long-running, are periodically updated by Chef to the latest opscode-ci, omnibus and build-essentials cookbooks.

Second, the version of omnibus we use to build chef is governed by `omnibus/Gemfile`. When software definitions or the omnibus framework is updated, this is the file that drives whether we pick it up.

The omnibus tooling versions are locked down with `omnibus/Gemfile.lock`, and can be updated by running `rake dependencies`.

### Test Versions

chef is tested by the [chef-acceptance framework](https://github.com/chef/chef-acceptance), which contains suites that are run on the Jenkins test machines. The definitions of the tests are in the `acceptance` directory. The version of chef-acceptance and test-kitchen, are governed by `acceptance/Gemfile`.

The test tooling versions are locked down with `acceptance/Gemfile.lock`, which can be updated by running `rake dependencies`.

## The Build Process

The actual Chef build process is done with Omnibus, and has several general steps:

1. `bundle install` from `chef/Gemfile.lock`
2. Reinstall any gems that came from git or path using `rake install`
3. appbundle chef, chef, test-kitchen and berkshelf
4. Put miscellaneous powershell scripts and cleanup

### Kicking Off The Build

The build is kicked off in Jenkins by running this on the machine (which is already the correct OS and already has the correct dependencies, loaded by the `omnibus` cookbook):

```
load-omnibus-toolchain.bat
cd chef/omnibus
bundle install
bundle exec omnibus build chef
```

This causes the [chef project definition](omnibus/config/projects/chef.rb) to load, which runs the [chef-complete](omnibus/config/software/chef-complete.rb) software definition, the primary software definition driving the whole build process. The reason we embed it all in a software definition instead of the project is to take advantage of omnibus caching: omnibus will invalidate the entire project (and recompile ruby, openssl, and everything else) if you change anything at all in the project file. Not so with a software definition.

### Installing the Gems

The primary build definition that installs the many Chef rubygems is [`software/chef.rb`](omnibus/software/chef.rb). This has dependencies on any binary libraries, ruby, rubygems and bundler. It has a lot of steps, so it uses a [library](omnibus/files/chef/build-chef.rb) to help reuse code and make it manageable to look at.

What it does:

1. Depends on software defs for pre-cached gems (see "Gems and Caching" below).
2. Installs all gems from the bundle:
   - Sets up a `.bundle/config` ([code](omnibus/files/chef/build-chef.rb#L17-L39)) with --retries=4, --jobs=1, --without=development,no_<platform>, and `build.config.nokogiri` to pass.
   - Sets up a common environment, standardizing the compilers and flags we use, in [`env`](omnibus/files/chef-gem/build-chef-gem.rb#L32-L54).
   - [Runs](omnibus/config/software/chef.rb#L68) `bundle install --verbose`
3. Reinstalls any gems that were installed via path:
   - [Runs](omnibus/files/chef/build-chef.rb#L80) `bundle list --paths` to get the installed directories of all gems.
   - For each gem not installed in the main gem dir, [runs](omnibus/files/chef/build-chef.rb#L89) `rake install` from the installed gem directory.
   - [Deletes](omnibus/files/chef/build-chef.rb#L139-L143) the bundler git cache and path- and git-installed gems from the build.
4. [Creates](omnibus/files/chef/build-chef.rb#L102-L152) `/opt/chef/Gemfile` and `/opt/chef/Gemfile.lock` with the gems that were installed in the build.

#### Gems and Caching

Some gems take a super long time to install (particularly native-compiled ones such as nokogiri and dep-selector-libgecode) and do not change version very often. In order to avoid doing this work every time, we take advantage of omnibus caching by separating out these gems into their own software definitions. [chef-gem-dep-selector-libgecode](omnibus/config/software/chef-gem-dep-selector-libgecode.rb) for example.

Each of these gems uses the `config/files/chef-gem/build-chef-gem` library to define itself. The name of the software definition itself indicates the .

We only create software definitions for long-running gems. Everything else is just installed in the [chef](omnibus/config/software/chef.rb) software definition in a big `bundle install` catchall.

Most gems we just install in the single `chef` software definition.

The first thing

### Appbundling

After the gems are installed, we *appbundle* them in [chef-appbundle](omnibus/config/software/chef-appbundle.rb). This creates binstubs that use the bundle to pin the software .

During the process of appbundling, we update the gem's `Gemfile` to include the locks in the top level `/opt/chef/Gemfile.lock`, so we can guarantee they will never pick up things outside the build. We then run `bundle lock` to update the gem's `Gemfile.lock`, and `bundle check` to ensure all the gems are actually installed. The appbundler then uses these pins.

### Other Cleanup

Finally, chef does several more steps including installing powershell scripts and shortcuts, and removing extra documentation to keep the build slim.

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
