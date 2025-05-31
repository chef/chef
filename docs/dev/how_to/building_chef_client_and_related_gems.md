# How to Build Chef Client and Associated Products



This page endeavors to explain the vagaries of building out Chef Client and its accoutrements. The team is responsible for several gems in addition to the Chef Client codebase. We release the following gems:

- Chef-Config
- Chef-Utils
- Chef-PowerShell
- Knife
- Chef-bin
- Chef-Client



### Contact Us: #chef-infra-dev in Slack

**Codebase**: [chef-powershell-shim](https://github.com/chef/chef-powershell-shim)

**Action**: Build

**Access**: Github Actions

**What to do**:

When you peruse the repo you’ll note that there are a number of directories here. You will need to manage the accompanying .NET code bases in addition to the chef-powershell code itself.

There are 2 ways to use this pipeline. The first is to merely merge your PR back into main once all the tests pass. This triggers an automated Github Actions pipeline that will push a compiled gem to RubyGems.org. The second way is to manually build and test the gem and then manually push it to Rubygems.org. You will need access to the RubyGems - chef-powershell repo via API key to do a manual upload. **NOTE**: This code base is entirely windows based. Meaning, you will compile and test on Windows and the gem will only run on a Windows device. The code supports PowerShell Core but the gcc libraries needed to run on Mac/Linux have not been built out yet.



**Codebase**: [win32-certstore](https://github.com/chef/win32-certstore)

**Access**: Pull Requests / Expeditor

**What to do**:

The Win32-Certstore code provides an FFI/Win32 based gem used to manage certificates on a Windows node.

This one is a bit gnarly, see the notes below. Chef Infra team has backlogged issues to add functionality to the C++ libraries. If you have some spare cycles, we need the help.

To start `git checkout -b`There are 2 parts of the code here. You’ll need to do your thing in C++ and then make sure the corresponding FFI/Ruby interfaces and methods are all working. Then push your branch back to main and open a PR. Once your code is green and merged, you’re done .   **NOTE:** This code base is Windows based and contains C++ code. You’ll need a windows machine to test on. You can probably get away with developing on Mac or Linux.



**Codebase**: [chef](https://github.com/chef/chef)

**Action**: Promote a Build

**Access**: Chef Internal Slack

**What to do**:

There are a few steps in performing a release. They are documented here : https://github.com/chef/chef/blob/main/docs/dev/how_to/releasing_chef_infra.md

In Essence:

1. Is your current build clean - no random errors, no busted tests?
2. Have you documented all the changes in this build? This is a critical step to help customers and partner understand the changes we’re releasing.
3. Promote the build
4. Announce the build in Slack to #sous-chefs and #general
5. Update Homebrew
6. Update Chocolatey
7. Backport to Chef 17 and Chef 16 as appropriate
   1. Git Pull Chef
   2. git checkout chef17
   3. git checkout -b my_branch_based_on_chef17
   4. Do my work on chef17 branch
   5. Merge it back to Chef17



**Codebase**: [chef](https://github.com/chef/chef)

**Action**: Build Chef Client

**Access**: Pull Requests / Expeditor

**What to do**:

You have a feature or a bug you just fixed. Now what? Write your tests and, run rake to look for linting errors, spelling mistakes etc. Then push your branch back to main and create a pull request. This kicks off a build that will run your code against all 20 or so operating systems we support. Builds take a while. Once your build starts you have 2-3 hours or so to do something else. Once your build passes, get it approved and merged back to main. You’re done, unless you’re in charge of releases this week, in which case see the item just above about promoting builds



**Codebase**: [chef](https://github.com/chef/chef)

**Action**: Ad Hoc builds

**Access**: Buildkite

**What to do**:

You have some code that may or may not really dodgy and you kinda need/want to see where the possible problems are with it. You can do an ad-hoc build against your branch to give it a go. To do that, you do this: There are 2 paths you can follow for a build. Chef stand-alone and Chef as part of the Chef Workstation product.

[Chef Client Ad-Hoc Build Site](https://buildkite.com/chef/chef-chef-master-omnibus-adhoc/)

[Chef Workstation Ad Hoc Build Site](https://buildkite.com/chef/chef-chef-workstation-master-omnibus-adhoc/)

Steps:

1. Click either link and if asked, confirm your login settings and then click the link in the verification email.

2. Once past that you’ll need to add a ‘Pipeline’ - create a name for your pipeline and git it the root of github repo you want to build from

3. Past that you’ll be asked to create a new build that uses your pipeline. Notice you can use any branch, you’ll enter yours here.

4. You can use the options page to add environment variables that are unique to your build or do things like build only Windows nodes:

   ```
   OMNIBUS_BUILD_FILTER=windows*
   ```
