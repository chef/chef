=====================================================
Community Contributions
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/community_contributions.rst>`__

We're glad you want to contribute to a Chef project! This guide will help answer common questions you may have during your first contribution.

Submitting Issues
=====================================================
Not every contribution comes in the form of code. Submitting, confirming, and triaging issues is an important task for any project. At Chef we use GitHub to track all project issues.

If you are familiar with Chef and know the component, that is causing you a problem, you can file an issue in the corresponding GitHub project. All of our Open Source Software can be found in our GitHub organization at https://github.com/chef. All projects include GitHub issue templates to help gather information needed for a thorough review.

We ask you not to submit security concerns via GitHub. For details on submitting potential security issues please see https://www.chef.io/security/.

In addition to GitHub issues, we also utilize a feedback site that helps our product team track and rank feature requests. If you have a feature request, this is an excellent place to start: https://feedback.chef.io.

The following repositories are the preferred locations for the creation of issues and bug reports:

.. list-table::
   :widths: 100 400
   :header-rows: 1

   * - Repo
     - URL
   * - chef-client
     - https://github.com/chef/chef
   * - Ohai
     - https://github.com/chef/ohai
   * - Chef DK
     - https://github.com/chef/chef-dk
   * - Chef Server
     - https://github.com/chef/chef-server
   * - Chef Manage
     - https://github.com/chef/chef-manage-issues
   * - Chef Push Jobs
     - https://github.com/chef/chef-push
   * - Chef Automate
     - please contact `Chef Support <https://www.chef.io/support/>`_

For additional support about Chef products, including documentation, learning, and opening tickets with the support team, see `Chef Support <https://www.chef.io/support/>`_ .

.. warning:: If you require a response from Chef per the terms of a support level agreement (SLA), please contact `Chef Support <https://www.chef.io/support/>`_ directly.

.. note:: Questions on how to use Chef should be sent as Support Tickets if you have an SLA, or asked on the `Chef Mailing List <https://discourse.chef.io/>`_, or `Chef Community Slack <https://community-slack.chef.io/>`_. Bug Trackers are not appropriate for general purpose questions that are not bugs.

Contribution Process
=====================================================
We have a 3 step process for contributions:

#. Commit changes to a git branch, making sure to sign-off those changes for the Developer Certificate of Origin.
#. Create a GitHub Pull Request for your change, following the instructions in the pull request template.
#. Perform a Code Review with the project maintainers on the pull request.

About the Apache License
=====================================================
Chef uses the Apache License Version 2 because it provides the same level of freedom for our users that we desire for ourselves. Based upon the Apache Licensing FAQ, it allows you to:

* freely download and use Chef software, in whole or in part, for personal, company internal, or commercial purposes;
* use Chef software in packages or distributions that you create.

It forbids you to:

* redistribute any piece of Chef-originated software without proper attribution;
* use any marks owned by Chef in any way that might state or imply that Chef endorses your distribution;
* use any marks owned by Chef in any way that might state or imply that you created the Chef software in question.

It requires you to:

* include a copy of the license in any redistribution you may make that includes Chef software;
* provide clear attribution to Chef for any distributions that include Chef software; attribution can be done in the NOTICE file for an application, by adding yourself as an author/copyright holder to the HEADER for an individual file, and by placing text in a header file saying that new work is based on previous work
* reuse work as long as the licensing terms of the reused work remains unchanged (i.e. The Apache License Version 2 also applies to the reused work)

It does not require you to:

* include the source of the Chef software itself, or of any modifications you may have made to it, in any redistribution you may assemble that includes it;
* submit changes that you make to the software back to Chef (though such feedback is encouraged).

It is our goal to run a successful, truly open source business. To that end, we are protecting our own rights by making them explicit in our choice of licensing: you have the same rights to our open source software that we do.

Developer Certification of Origin (DCO)
=====================================================

To make a good faith effort to ensure the criteria of the Apache License are met, Chef requires the Developer Certificate of Origin (DCO) process to be followed.

The DCO is an attestation attached to every contribution made by every developer. In the commit message of the contribution, the developer simply adds a Signed-off-by statement and thereby agrees to the DCO, which you can find below or at http://developercertificate.org/.

.. code-block:: console

    Developer's Certificate of Origin 1.1

    By making a contribution to this project, I certify that:

    (a) The contribution was created in whole or in part by me and I
        have the right to submit it under the open source license
        indicated in the file; or

    (b) The contribution is based upon previous work that, to the
        best of my knowledge, is covered under an appropriate open
        source license and I have the right under that license to
        submit that work with modifications, whether created in whole
        or in part by me, under the same open source license (unless
        I am permitted to submit under a different license), as
        Indicated in the file; or

    (c) The contribution was provided directly to me by some other
        person who certified (a), (b) or (c) and I have not modified
        it.

    (d) I understand and agree that this project and the contribution
        are public and that a record of the contribution (including
        all personal information I submit with it, including my
        sign-off) is maintained indefinitely and may be redistributed
        consistent with this project or the open source license(s)
        involved.

Chef does not merge any pull requests made against an Chef-managed open source repository until each commit has been signed for the DCO, with three exceptions:

* "Obvious Fixes" (as described below)
* Pull requests made against the docs.chef.io documentation repository (https://github.com/chef/chef-web-docs)
* Pull requests that contain only documentation updates made against projects where the documentation is embedded in the project's repository (i.e. the ``docs`` directory in the ``chef/inspec`` repository)

The "Obvious Fix" Rule
=====================================================
Chef's contribution policy is aimed at encouraging broad participation from our community, and minimizing risks to Chef and our community due to inappropriate contributions of the intellectual property of others.

As a general standard, Chef requires every contribution to by signed for the Developer Certificate of Origin (DCO).

HOWEVER, very small contributions such as fixing spelling errors, where the content is small enough to not be considered intellectual property, can be submitted by a contributor as a patch, without a DCO sign-off. If you submit an obvious fix without a DCO sign-off, then you are agreeing that your submission is not independently copyrightable. The purpose of this exception is to lower the barrier for new contributors to make contributions while retaining the integrity of the project and our community.

How does the Obvious Fix Rule Work?
-----------------------------------------------------
Any committer may commit fixes without a DCO sign-off for obvious typos, grammar mistakes, and formatting problems wherever they may be — in the web pages, API documentation, source code, etc.

Whenever you invoke the "obvious fix" rule, please say so in your commit message. For example:

.. code-block:: bash

   ------------------------------------------------------------------------
   commit 370adb3f82d55d912b0cf9c1d1e99b132a8ed3b5
   Author: Julia Child <juliachild@chef.io>
   Date:   Wed Sep 18 11:44:40 2015 -0700

     Fix typo in the README.

     Obvious fix.

   ------------------------------------------------------------------------

What qualifies as an Obvious Fix?
-----------------------------------------------------
An obvious fix is a pull request that does not contain creative work. We rely on your judgment to determine what is "obvious"; if you're not sure, just ask by sending an email to: oss AT getchef DOT com.

As a rule of thumb, changes are obvious fixes if they do not introduce any new functionality or creative thinking. As long as the change does not affect functionality, some likely examples include the following:

* Spelling/grammar fixes;
* Correcting typos;
* Cleaning up comments in the code;
* Changes to white space or formatting;
* Bug fixes that change default return values or error codes stored in constants, literals, or simple variable types;
* Adding logging messages or debugging output;
* Changes to 'metadata' files like Gemfile, rebar.config, Makefile, app.config, sys.config, .gitignore, example configuration files, build scripts, etc.;
* Changes that reflect outside facts, like renaming a build directory or changing a constant;
* Changes in build or installation scripts;
* Re-ordering of objects or subroutines within a source file (such as alphabetizing routines);
* Moving source files from one directory or package to another, with no changes in code;
* Breaking a source file into multiple source files, or consolidating multiple source files into one source file, with no change in code behavior;
* Changes to words or phrases isolated from their context;
* Changes to typeface.

Things that would still require a DCO sign-off before submitting would likely include stuff like the following:

* Any of the above actions that result in a change in functionality;
* A new feature;
* A translation;
* Extensive or creative comments.

Use git
=====================================================
Chef is maintained on GitHub. To contribute to Chef, such as submitting a pull request, requires using GitHub and git. The sections below describe how to use git to set up the Chef repository, keep it current and synchronized, and how to use branches to submit pull requests.

Set Up Repo
-----------------------------------------------------
Use the following steps to set up a development repository for Chef:

#. Set up a GitHub account.
#. Fork the https://github.com/chef/chef repository to your GitHub account.
#. Clone the https://github.com/chef/chef repository:

   .. code-block:: bash

      $ git clone git@github.com:yourgithubusername/chef.git

#. From the command line, browse to the ``chef/`` directory:

   .. code-block:: bash

      $ cd chef/

#. From the ``chef/`` directory, add a remote named ``chef``:

   .. code-block:: bash

      $ git remote add chef git://github.com/chef/chef.git

#. Verify:

   .. code-block:: bash

      $ git config --get-regexp "^remote\.chef"

   which should return something like:

   .. code-block:: bash

      remote.chef.url git://github.com/chef/chef.git
      remote.chef.fetch +refs/heads/*:refs/remotes/chef/*

#. Adjust your branch to track the ``chef/master`` remote branch:

   .. code-block:: bash

      $ git config --get-regexp "^branch\.master"

   which should return something like:

   .. code-block:: bash

      branch.master.remote origin
      branch.master.merge refs/heads/master

   and then change it:

   .. code-block:: bash

      $ git config branch.master.remote chef

Keep Master Current
-----------------------------------------------------
Use the following steps to keep the master branch up to date.

#. Run:

   .. code-block:: bash

      $ git checkout master

#. And then run:

   .. code-block:: bash

      $ git pull --rebase

The following ``rakefile`` can be used to update Chef, Ohai, and cookbooks. Edit as necessary:

.. code-block:: ruby

   projects = %w[chef cookbooks ohai]
   chef = "#{ENV['HOME']}/projects/chef"

   desc 'Update local repositories from upstream'
   task :update do
     projects.each do |p|
       Dir.chdir('#{chef}/#{p}') do
         sh 'git fetch chef'
         sh 'git rebase chef/master master'
       end
     end
   end

Sync Master
-----------------------------------------------------
Use the following steps to synchronize the master branch.

#. Run:

   .. code-block:: bash

      $ git fetch chef

#. And then run:

   .. code-block:: bash

      $ git rebase chef/master master

   .. note:: Use ``rebase`` instead of ``merge`` to ensure that a linear history is maintained that does not include unnecessary merge commits. ``rebase`` will also rewind, apply, and then reapply commits to the ``master`` branch.

Use Branch
-----------------------------------------------------
Commits to the Chef repositories should never be made against the master branch. Use a topic branch instead. A topic branch solves a single and unique problem and often maps closely to an issue being tracked in the repository. For example, a topic branch to add support for a new init system or a topic branch to resolve a bug that occurs in a specific version of CentOS. Ideally, a topic branch is named in a way that associates it closely with the issue it is attempting to resolve. This helps ensure that others may easily find it.

Use the following steps to create a topic branch:

#. For a brand new clone of the Chef repository (that was created using the steps listed earlier), fetch the ``opscode`` remote:

   .. code-block:: bash

      $ git fetch chef

#. Create an appropriately named tracking branch:

   .. code-block:: bash

      $ git checkout --track -b CHEF-XX chef/master

   Set up a topic branch to track ``chef/master``. This allows commits to be easily rebased prior to merging.

#. Make your changes, and then commit them:

   .. code-block:: bash

      $ git status

#. And then run:

   .. code-block:: bash

      $ git commit <filespec>

#. Rebase the commits against ``chef/master``. After work in the topic branch is finished, rebase these commits against the upstream master. Do this manually with ``git fetch`` followed by a ``git rebase`` or use ``git pull --rebase``.

   git will let you know if there are any problems. In the event of problems, fix them as directed, and then mark as fixed with a ``git add``, and then continue the rebase process using ``git rebase --continue``.

   For example:

   .. code-block:: bash

      $ git fetch chef

   followed by:

   .. code-block:: bash

      $ git rebase chef/master CHEF-XX

   Or:

   .. code-block:: bash

      $ git pull --rebase

#. Push the local topic branch to GitHub:

   .. code-block:: bash

      $ git push origin CHEF-XX

#. Send a GitHub pull request for the changes, and then update the Chef ticket with the appropriate information.

Delete Branch
-----------------------------------------------------
After work has been merged by the branch maintainer, the topic branch is no longer necessary and should be removed.

#. Synchronize the local master:

   .. code-block:: bash

      $ git checkout master

   followed by:

   .. code-block:: bash

      $ git pull --rebase

#. Remove the local branch using ``-d`` to ensure that it has been merged by upstream. This option will not delete a branch that is not an ancestor of the current ``HEAD``. From the git man page:

   .. code-block:: bash

      -d
        Delete a branch. The branch must be fully merged in HEAD.
      -D
        Delete a branch irrespective of its merged status.

#. Remove the local branch:

   .. code-block:: bash

      $ git branch -d CHEF-XX

   Or remove the remote branch by using the full syntax to ``push`` and by omitting a source branch:

   .. code-block:: bash

      $ git push origin :CHEF-XX


