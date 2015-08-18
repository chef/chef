# Chef 
[![Code Climate](https://codeclimate.com/github/opscode/chef.png)](https://codeclimate.com/github/opscode/chef)
[![Build Status Master](https://travis-ci.org/chef/chef.svg?branch=master)](https://travis-ci.org/chef/chef)
[![Build Status Master](https://ci.appveyor.com/api/projects/status/github/chef/chef?branch=master&svg=true&passingText=master%20-%20Ok&pendingText=master%20-%20Pending&failingText=master%20-%20Failing)](https://ci.appveyor.com/project/Chef/chef/branch/master)

Want to try Chef? Get started with [learnchef](https://learn.chef.io)

* Documentation: [http://docs.chef.io](http://docs.chef.io)
* Source: [http://github.com/chef/chef/tree/master](http://github.com/chef/chef/tree/master)
* Tickets/Issues: [https://github.com/chef/chef/issues](https://github.com/chef/chef/issues)
* IRC: `#chef` and `#chef-hacking` on Freenode
* Mailing list: [http://lists.opscode.com](http://lists.opscode.com)

Chef is a configuration management tool designed to bring automation to your
entire infrastructure.

This README focuses on developers who want to modify Chef source code.
If you just want to use Chef, check out these resources:

* [learnchef](https://learn.chef.io): Getting started guide
* [http://docs.chef.io](http://docs.chef.io): Comprehensive User Docs
* [Installer Downloads](https://www.chef.io/download-chef-client/): Install Chef as a complete package

## Installing From Git

**NOTE:** Unless you have a specific reason to install from source (to
try a new feature, contribute a patch, or run chef on an OS for which no
package is available), you should head to the [installer page](https://www.chef.io/download-chef-client/)
to get a prebuilt package.

### Prerequisites

Install these via your platform's preferred method (apt, yum, ports,
emerge, etc.):

* git
* C compiler, header files, etc. On Ubuntu/Debian, use the
  `build-essential` package.
* ruby 2.0.0 or later
* rubygems
* bundler

### Chef Installation

Then get the source and install it:

    # Clone this repo
    git clone https://github.com/chef/chef.git
    
    # cd into the source tree
    cd chef

    # Install dependencies with bundler
    bundle install

    # Build a gem
    rake gem

    # Install the gem you just built
    gem install pkg/chef-VERSION.gem


## Contributing/Development

Before working on the code, if you plan to contribute your changes, you need to
read the
[Chef Contributions document](http://docs.chef.io/community_contributions.html).

The general development process is:

1. Fork this repo and clone it to your workstation.
2. Create a feature branch for your change.
3. Write code and tests.
4. Push your feature branch to github and open a pull request against
   master.

Once your repository is set up, you can start working on the code. We do use
TDD with RSpec, so you'll need to get a development environment running.
Follow the above procedure ("Installing from Git") to get your local
copy of the source running.

## Reporting Issues

Issues can be reported by using [GitHub issues](https://github.com/chef/chef/issues).

Full details on how to report issues can be found in the [CONTRIBUTING](https://github.com/chef/chef/blob/master/CONTRIBUTING.md#-chef-issue-tracking) doc.

Note that this repository is primarily for reporting chef-client issues.
For reporting issues against other Chef projects, please look up the appropriate repository
to report issues against in the Chef docs in the
[community contributions section](https://docs.chef.io/community_contributions.html#issues-and-bug-reports).
If you can't detemine the appropriate place to report an issue, then please open it
against the repository you think best fits and it will be directed to the appropriate project.

## Testing

We use RSpec for unit/spec tests. It is not necessary to start the development
environment to run the specs--they are completely standalone.

    # Run All the Tests
    bundle exec rake spec

    # Run a Single Test File
    bundle exec rspec spec/PATH/TO/FILE_spec.rb

    # Run a Subset of Tests
    bundle exec rspec spec/PATH/TO/DIR

When you submit a pull request, we will automatically run the functional and unit
tests in spec/functional/ and spec/unit/ respectively. These will be run on Ubuntu
through Travis CI, and on Windows through AppVeyor. The status of these runs will
be displayed with your pull request.

# License

Chef - A configuration management system

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Adam Jacob (<adam@chef.io>)
| **Copyright:**       | Copyright (c) 2008-2015 Chef Software, Inc.
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
