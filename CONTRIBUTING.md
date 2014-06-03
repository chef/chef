# Contributing to Chef

We are glad you want to contribute to Chef!

We utilize **Github Issues** for issue tracking and contributions. You can contribute in two ways:

1. Reporting an issue or making a feature request [here](#issues).
2. Adding features or fixing bugs yourself and contributing your code to Chef.

## Contribution Process

We have an easy 3 step process that utilizes **Github Issues**:

1. Spare two minutes to sign our
  [Contributor License Agreement (CLA)](https://secure.echosign.com/public/hostedForm?formid=PJIF5694K6L)
  or [Corporate CLA](https://secure.echosign.com/public/hostedForm?formid=PIE6C7AX856) online.
2. Create a Github Pull Request.
3. Do [Code Review](#cr) with the **Chef Engineering Team** or **Chef Core Committers** on the pull request.

### <a name="pulls"></a> Chef Pull Requests

Chef is built to last. We thrive to ensure high quality throughout Chef experience. In order to ensure
  this we require a couple of things for all pull requests to Chef:

1. **Tests:** To ensure high quality code and protect against future regressions, we require all the
  code in Chef to have at least unit test coverage.
2. **Green Travis Run:** We use [Travis CI](https://travis-ci.org/) in order to run our tests
  continuously on all the pull requests. We require the Travis runs to succeed on every pull
  request before being merged.

In addition to this it would be nice to include the description of the problem you are solving
  with your change. You can use [Chef Issue Template](#issuetemplate) in the description section
  of the pull request.

### <a name="cr"></a> Chef Code Review Process

The Chef Code Review Process happens on Github pull requests. See
  [this article](https://help.github.com/articles/using-pull-requests) if you're not
  familiar with Github Pull Requests.

Once you a pull request, the **Chef Engineering Team** or **Chef Core Committers** will review your code
  and respond to you with any feedback they might have. The process at this point is as follows:

1. 2 thumbs-ups are required from the **Chef Engineering Team** or **Chef Core Committers** for all merges.
2. When ready, your pull request will be tagged with label `Ready For Merge`.
3. **In at most 2 weeks** your patch will be merged into `master` including necessary documentation updates
  and you will be included in `CHANGELOG.md`.

If you would like to learn about when your code will be available in a release of Chef, read more about
  [Chef Release Process](#release).

### Contributor License Agreement (CLA)
Licensing is very important to open source projects, it helps ensure the
  software continues to be available under the terms that the author desired.

Chef uses [the Apache 2.0 license](https://github.com/opscode/chef/blob/master/LICENSE)
  to strike a balance between open contribution and allowing you to use the
  software however you would like to.

The license tells you what rights you have that are provided by the copyright holder.
  It is important that the contributor fully understands what rights they are
  licensing and agrees to them. Sometimes the copyright holder isn't the contributor,
  most often when the contributor is doing work for a company.

To make a good faith effort to ensure these criteria are met, Chef requires a CLA
  or a Corporate CLA for contributions. This is not related to copyrights and it
  helps us avoid continually checking with our lawyers for your patches.

It only takes a few minutes to complete a CLA, and you retain the copyright to your contribution.

You can complete our CLA
  [online](https://secure.echosign.com/public/hostedForm?formid=PJIF5694K6L).
  If you're contributing on behalf of your employer, have your employer fill out our
  [Corporate CLA](https://secure.echosign.com/public/hostedForm?formid=PIE6C7AX856) instead.

### Chef Obvious Fix Policy

**TODO: Include some information here.**

## <a name="issues"></a> Chef Issue Tracking

Chef Issue Tracking is handled using Github Issues.

If you are familiar with Chef and know the component that is causing you a problem or if you
  have a feature request on a specific component you can file an issue in the corresponding
  Github project. All of our Open Source Software can be found in our
  [Github organization](https://github.com/opscode/).

Otherwise you can file your issue in the [Chef project](https://github.com/opscode/chef/issues)
  and we will make sure it gets filed against the appropriate project.

In order to decrease the back and forth an issues and help us get to the bottom of them quickly
  we use below issue template. You can copy paste this code into the issue you are opening and
  edit it accordingly.

<a name="issuetemplate"></a>
```
### Version:
[Version of the project installed]

### Environment: [Details about the environment such as the Operating System, cookbook details, etc...]

### Scenario:
[What you are trying to achieve and you can't?]



### Repro Steps:
[If you are filing an issue what are the things we need to do in order to repro your problem?]


### Expected Result:
[What are you expecting to happen as the consequence of above repro steps?]


### Actual Result:
[What actually happens after the repro steps?]
```

## <a name="release"></a> Chef Release Cycles

Our primary shipping vehicle is operating system specific packages that includes
  all the requirements of Chef.

We also release our software as gems to [Rubygems](http://rubygems.org/) but we strongly
  recommend using Chef packages since they are the only combination of native libraries &
  gems required by Chef that we test throughly.

Our version numbering closely follows [Semantic Versioning](http://semver.org/) standard. Our
  standard version numbers look like X.Y.Z which mean:

* X is a major release, which may not be fully compatible with prior major releases
* Y is a minor release, which adds both new features and bug fixes
* Z is a patch release, which adds just bug fixes

We frequently make `alpha` and `beta` releases with version numbers that look like
  `X.Y.Z.alpha.0` or `X.Y.Z.beta.1`. These releases are still well tested but not as
  throughly as **Minor** or **Patch** releases.

We do a `Minor` release approximately every 3 months and `Patch` releases on a when-needed
  basis for regressions, significant bugs, and security issues.

Announcements of releases are available on [Chef Blog](http://www.getchef.com/blog) when they are
  available.
  
  **TODO**: Can I sign up for a mailing list to get notification of releases?

## Chef Community

Chef is made possible by a strong community of developers and system administrators. If you have
  any questions or if you would like to get involved in the Chef Community you can check out:

* [chef](http://lists.opscode.com/sympa/info/chef) and [chef-dev](http://lists.opscode.com/sympa/info/chef-dev) mailing lists
* \#chef and \#chef-hacking IRC channels on irc.freenode.net

Also here are some additional pointers to some awesome Chef content:

**TODO**: Any blogs of community folks that we would like to put in here?

* [Chef Docs](http://docs.opscode.com/)
* [LearnChef](https://learnchef.opscode.com/)
* [Chef Inc](http://www.getchef.com/)
