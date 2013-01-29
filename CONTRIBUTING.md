# Contributing to Chef

We are glad you want to contribute to Chef! The first step is the desire to improve the project.

You can find the answers to additional frequently asked questions [on the wiki](http://wiki.opscode.com/display/chef/How+to+Contribute).

## Quick-contribute

*   Create an account on our [bug tracker](http://tickets.opscode.com)
*   Sign our contributor agreement (CLA) [
online](https://secure.echosign.com/public/hostedForm?formid=PJIF5694K6L)  
    (keep reading if you're contributing on behalf of your employer)
* Create a ticket for your change on the [bug tracker](http://tickets.opscode.com)
* Link to your patch as a rebased git branch or pull request from the ticket
* Resolve the ticket as fixed

We regularly review contributions and will get back to you if we have any suggestions or concerns.

## The Apache License and the CLA/CCLA

Licensing is very important to open source projects, it helps ensure the software continues to be available under the terms that the author desired.
Chef uses the Apache 2.0 license to strike a balance between open contribution and allowing you to use the software however you would like to. 

The license tells you what rights you have that are provided by the copyright holder. It is important that the contributor fully understands what rights
they are licensing and agrees to them. Sometimes the copyright holder isn't the contributor, most often when the contributor is doing work for a company.

To make a good faith effort to ensure these criteria are met, Opscode requires a Contributor License Agreement (CLA) or a Corporate Contributor License
Agreement (CCLA) for all contributions. This is without exception due to some matters not being related to copyright and to avoid having to continually
check with our lawyers about small patches.

It only takes a few minutes to complete a CLA, and you retain the copyright to your contribution.

You can complete our contributor agreement (CLA) [
online](https://secure.echosign.com/public/hostedForm?formid=PJIF5694K6L).  If you're contributing on behalf of your employer, have
your employer fill out our [Corporate CLA](https://secure.echosign.com/public/hostedForm?formid=PIE6C7AX856) instead.

## Ticket Tracker (JIRA)

The [ticket tracker](http://tickets.opscode.com) is the most important documentation for the code base. It provides significant historical information,
such as:

* Which release a bug fix is included in
* Discussion regarding the design and merits of features
* Error output to aid in finding similar bugs

Each ticket should aim to fix one bug or add one feature. 

## Using git

You can get a quick copy of the chef repository by running `git clone git://github.com/opscode/chef.git`. 

For collaboration purposes, it is best if you create a Github account and fork the repository to your own account. 
Once you do this you will be able to push your changes to your Github repository for others to see and use.

### Branches and Commits

You should submit your patch as a git branch named after the ticket, such as CHEF-1337.
This is called a _topic branch_ and allows users to associate a branch of code with the ticket. 

It is a best practice to have your commit message have a _summary line_ that includes the ticket number,
followed by an empty line and then a brief description of the commit. This also helps other contributors
understand the purpose of changes to the code.

    CHEF-3435: Create deploy dirs before calling scm_provider
        
    The SCM providers have an assertation that requires the deploy directory to
    exist. The deploy provider will create missing directories, we don't converge
    the actions before we call run_action against the SCM provider, so it is not
    yet created. This ensures we run any converge actions waiting before we call
    the SCM provider.

Remember that not all users use Chef in the same way or on the same operating systems as you, so it is
helpful to be clear about your use case and change so they can understand it even when it doesn't apply to them.

### Github and Pull Requests

All of Opscode's open source projects are available on [Github](http://www.github.com/opscode).

We don't require you to use Github, and we will even take patch diffs attached to tickets on the tracker. 
However Github has a lot of convenient features, such as being able to see a diff of changes between a
pull request and the main repository quickly without downloading the branch.

If you do choose to use a pull request, please provide a link to the pull request from the ticket __and__
a link to the ticket from the pull request. Because pull requests only have two states, open and closed,
we can't easily filter pull requests that are waiting for a reply from the author for various reasons.

### More information

Additional help with git is available on the [Working with Git](http://wiki.opscode.com/display/chef/Working+with+Git) wiki page.

## Functional and Unit Tests

There are rspec unit tests in the 'spec' directory. If you don't have rspec already installed, you can use the 'bundler'
gem to help you get the necessary prerequisites by running `sudo gem install bundler` and then `bundle install` from
the chef respository. You can run the chef client spec tests by running `rspec spec/*` or `rake spec` from the chef 
directory of the chef repository.

These tests should pass successfully on Ruby 1.8 and 1.9 on all of the platforms that Chef runs on. It is good to run the tests 
once on your system before you get started to ensure they all pass so you have a valid baseline. After you write your patch,
run the tests again to see if they all pass.

If any don't pass, investigate them before submitting your patch. 

These tests don't modify your system, and sometimes tests fail because a command that would be run has changed because of your
patch. This should be a simple fix. Other times the failure can show you that an important feature no longer works because of
your change.

Any new feature should have unit tests included with the patch with good code coverage to help protect it from future changes.
Similarly, patches that fix a bug or regression should have a _regression test_. Simply put, this is a test that would fail
without your patch but passes with it. The goal is to ensure this bug doesn't regress in the future. Consider a regular
expression that doesn't match a certain pattern that it should, so you provide a patch and a test to ensure that the part
of the code that uses this regular expression works as expected. Later another contributor may modify this regular expression
in a way that breaks your use cases. The test you wrote will fail, signalling to them to research your ticket and use case
and accounting for it.

## Code Review

Opscode regularly reviews code contributions and provides suggestions for improvement in the code itself or the implementation.

We find contributions by searching the ticket tracker for _resolved_ tickets with a status of _fixed_. If we have feedback we will
reopen the ticket and you should resolve it again when you've made the changes or have a response to our feedback. When we believe
the patch is ready to be merged, we update the status to _Fix Reviewed_.

Depending on the project, these tickets are then merged within a week or two, depending on the current release cycle. At this
point the ticket status will be updated to _Fix Committed_ or _Closed_.

Please see the [Code Review](http://wiki.opscode.com/display/chef/Code+Review) page on the wiki for additional information.

## Release Cycle

The versioning for the Chef project is X.Y.Z.

* X is a major release, which may not be fully compatible with prior major releases
* Y is a minor release, which adds both new features and bug fixes
* Z is a patch release, which adds just bug fixes

Major releases and have historically been once a year. Minor releases for Chef average every two months and patch releases come as needed.

There are usually beta releases and release candidates (RC) of major and minor releases announced on 
the [chef-dev mailing list](http://lists.opscode.com/sympa/info/chef-dev). Once an RC is released, we wait at least three
days to allow for testing for regressions before the final release. If a blocking regression is found then another RC is made containing
the fix and the timer is reset.

Once the official release is made, the release notes are available on the [Opscode blog](http://www.opscode.com/blog).

## Working with the community

These resources will help you learn more about Chef and connect to other members of the Chef community:

* [chef](http://lists.opscode.com/sympa/info/chef) and [chef-dev](http://lists.opscode.com/sympa/info/chef-dev) mailing lists
* #chef and #chef-hacking IRC channels on irc.freenode.net
* [Community Cookbook site](http://community.opscode.com)
* [Chef wiki](http://wiki.opscode.com/display/chef)
* Opscode Chef [product page](http://www.opscode.com/chef)

