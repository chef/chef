# Contributing to Chef

We are glad you want to contribute to Chef!

We utilize **Github Issues** for issue tracking and contributions. You can contribute in two ways:

1. Reporting an issue or making a feature request [here](#issues).
2. Adding features or fixing bugs yourself and contributing your code to Chef.

## Contribution Process

We have a 3 step process that utilizes **Github Issues**:

1. Sign or be added to an existing [Contributor License Agreement (CLA)](https://supermarket.chef.io/become-a-contributor).
2. Create a Github Pull Request.
3. Do [Code Review](#cr) with the **Chef Engineering Team** or **Chef Core Committers** on the pull request.

### Chef Pull Requests

Chef is built to last. We strive to ensure high quality throughout the Chef experience. In order to ensure this, we require a couple of things for all pull requests to Chef:

1. **Tests:** To ensure high quality code and protect against future regressions, we require all the code in Chef to have at least unit test coverage. See the [spec/unit](https://github.com/chef/chef/tree/master/spec/unit) directory for the existing tests and use `bundle exec rake spec` to run them.
2. **Green Travis Run:** We use [Travis CI](https://travis-ci.org/) in order to run our tests continuously on all the pull requests. We require the Travis runs to succeed on every pull request before being merged.

### Chef Code Review Process

The Chef Code Review process happens on Github pull requests. See [this article](https://help.github.com/articles/using-pull-requests) if you're not familiar with Github Pull Requests.

Once you open a pull request, the **Chef Engineering Team** or **Chef Core Committers** will review your code and respond to you with any feedback they might have. The process at this point is as follows:

1. 2 thumbs-ups are required from the **Chef Engineering Team** or **Chef Core Committers** for all merges.
2. When ready, your pull request will be tagged with label `Ready For Merge`.
3. Your patch will be merged into `master` including necessary documentation updates and you will be included in `CHANGELOG.md`. Our goal is to have patches merged in 2 weeks after they are marked to be merged.

If you would like to learn about when your code will be available in a release of Chef, read more about [Chef Release Cycles](#chef-release-cycles).

### Contributor License Agreement (CLA)

Licensing is very important to open source projects. It helps ensure the software continues to be available under the terms that the author desired.

Chef uses [the Apache 2.0 license](https://github.com/chef/chef/blob/master/LICENSE) to strike a balance between open contribution and allowing you to use the software however you would like to.

The license tells you what rights you have that are provided by the copyright holder. It is important that the contributor fully understands what rights they are licensing and agrees to them. Sometimes the copyright holder isn't the contributor, such as when the contributor is doing work for a company.

To make a good faith effort to ensure these criteria are met, Chef requires an Individual CLA or a Corporate CLA for contributions. This agreement helps ensure you are aware of the terms of the license you are contributing your copyrighted works under, which helps to prevent the inclusion of works in the projects that the contributor does not hold the rights to share.

It only takes a few minutes to complete a CLA, and you retain the copyright to your contribution.

You can complete our [Individual CLA](https://supermarket.chef.io/icla-signatures/new) online. If you're contributing on behalf of your employer and they retain the copyright for your works, have your employer fill out our [Corporate CLA](https://supermarket.chef.io/ccla-signatures/new) instead.

### Chef Obvious Fix Policy

Small contributions such as fixing spelling errors, where the content is small enough to not be considered intellectual property, can be submitted by a contributor as a patch, without a CLA.

As a rule of thumb, changes are obvious fixes if they do not introduce any new functionality or creative thinking. As long as the change does not affect functionality, some likely examples include the following:

- Spelling / grammar fixes
- Typo correction, white space and formatting changes
- Comment clean up
- Bug fixes that change default return values or error codes stored in constants
- Adding logging messages or debugging output
- Changes to 'metadata' files like Gemfile, .gitignore, build scripts, etc.
- Moving source files from one directory or package to another

**Whenever you invoke the "obvious fix" rule, please say so in your commit message:**

```
------------------------------------------------------------------------
commit 370adb3f82d55d912b0cf9c1d1e99b132a8ed3b5
Author: danielsdeleo <dan@chef.io>
Date:   Wed Sep 18 11:44:40 2013 -0700

  Fix typo in config file docs.

  Obvious fix.

------------------------------------------------------------------------
```

## Chef Issue Tracking

Chef Issue Tracking is handled using Github Issues.

If you are familiar with Chef and know the component that is causing you a problem or if you have a feature request on a specific component you can file an issue in the corresponding Github project. All of our Open Source Software can be found in our [Github organization](https://github.com/chef/).

There is also a listing of the various Chef products and where to file issues that can be found in the Chef docs in the [community contributions section](https://docs.chef.io/community_contributions.html#issues-and-bug-reports).

Otherwise you can file your issue in the [Chef project](https://github.com/chef/chef/issues) and we will make sure it gets filed against the appropriate project.

### Useful Github Queries

Contributions go through a review process to improve code quality and avoid regressions. Managing a large number of contributions requires a workflow to provide queues for work such as triage, code review, and merging. A semi-formal process has evolved over the life of the project. Chef maintains this process pending community development and acceptance of an [RFC](https://github.com/chef/chef-rfc). These queries will help track contributions through this process:

- [Issues that are not assigned to a team](https://github.com/chef/chef/issues?q=is%3Aopen+-label%3AAIX+-label%3ABSD+-label%3Awindows+-label%3A%22Chef+Core%22++-label%3A%22Dev+Tools%22+-label%3AUbuntu+-label%3A%22Enterprise+Linux%22+-label%3A%22Ready+For+Merge%22+-label%3AMac+-label%3ASolaris+)
- [Untriaged Issues](https://github.com/chef/chef/issues?q=is%3Aopen+is%3Aissue+-label%3ABug+-label%3AEnhancement+-label%3A%22Tech+Cleanup%22+-label%3A%22Ready+For+Merge%22)
- [PRs to be Reviewed](https://github.com/chef/chef/labels/Pending%20Maintainer%20Review)
- [Suitable for First Contribution](https://github.com/chef/chef/labels/Easy)

## Chef Release Cycles

Our primary shipping vehicle is operating system specific packages that includes all the requirements of Chef. We call these [Omnibus packages](https://github.com/chef/omnibus)

We also release our software as gems to [Rubygems](https://rubygems.org/) but we strongly recommend using Chef packages since they are the only combination of native libraries & gems required by Chef that we test throughly.

Our version numbering roughly follows [Semantic Versioning](http://semver.org/) standard. Our standard version numbers look like X.Y.Z which mean:

- X is a major release, which may not be fully compatible with prior major releases
- Y is a minor release, which adds both new features and bug fixes
- Z is a patch release, which adds just bug fixes

After shipping a release of Chef we bump the `Minor` version by one to start development of the next minor releaae. All merges to master trigger an increment of the `Patch` version, and a build through our internal testing pipeline. We do a `Minor` release approximately every month, which consist of shipping one of the already auto-incremented and tested `Patch` versions. For example after shiping 12.10.24, we incremented Chef to 12.11.0\. From there 18 commits where merged bringing the version to 12.11.18, which we shipped as an omnibus package.

Announcements of releases are made to the [chef mailing list](https://discourse.chef.io/c/chef-release) when they are available.

## Chef Community

Chef is made possible by a strong community of developers and system administrators. If you have any questions or if you would like to get involved in the Chef community you can check out:

- [Chef Mailing List](https://discourse.chef.io/)
- [Chef Community Slack](https://community-slack.chef.io/)

Also here are some additional pointers to some awesome Chef content:

- [Chef Docs](https://docs.chef.io/)
- [Learn Chef](https://learn.chef.io/)
- [Chef Inc.](https://www.chef.io/)
