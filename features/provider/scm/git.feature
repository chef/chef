@provider @git @gitonly

Feature: Git
  In order to use files stored in git so I can deploy apps and use edge versions of software
  As a Developer
  I want to clone and update git repositories

  Scenario: Clone a git repo and do a no-op sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'
      
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'gitchef/.git/config' should exist
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

     When I run the chef-client again
     Then the run should exit '0'
      And a file named 'gitchef/.git/config' should exist
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

  Scenario: Clone a git repo, change the branch, and get it changed back
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'
 
     When I check out 'foobranch' in 'gitchef'
     Then the file named 'gitchef/what_revision_am_i' should contain 'foo'
      And the current branch in 'gitchef' should be 'foobranch'
      And a branch named 'deploy' should exist in 'gitchef'

     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

  Scenario: Clone a git repo, change file AND change the branch, and get both changed back
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'
 
     When I check out 'foobranch' in 'gitchef'
      And I change the test git repo file named 'what_revision_am_i' to '3'
     Then the file named 'gitchef/what_revision_am_i' should contain 'foo'
      And the current branch in 'gitchef' should be 'foobranch'
      And a branch named 'deploy' should exist in 'gitchef'

     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

  Scenario: Clone a git repo and do not overwrite a local change until the repository changes
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'
      
     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I change the file named 'gitchef/what_revision_am_i' to 'foo'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'foo'

     When I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '3'

  Scenario: Clone a git repo with a destination
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-destination'
      
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'gitchef/what_revision_am_i' should exist
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

  Scenario: Clone a git repo with additional repositories
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-remotes'

     When I run the chef-client
     Then the run should exit '0'
      And a remote repository named 'hi' should exist in 'gitchef'
      And a remote repository named 'lo' should exist in 'gitchef'
      And a remote repository named 'waugh' should exist in 'gitchef'

     When I remove the remote repository named 'lo' from 'gitchef'
      And I run the chef-client again
     Then the run should exit '0'
      And a remote repository named 'hi' should exist in 'gitchef'
      And a remote repository named 'lo' should exist in 'gitchef'
      And a remote repository named 'waugh' should exist in 'gitchef'

  Scenario: Clone a git repo with a branch, modify the branch, and sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-branch'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'foo'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

     When I change the test git repo file named 'what_revision_am_i' to 'bar' in branch 'foobranch'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'bar'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

  Scenario: Clone a git repo with a reference, check out a different tag and change it back
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-reference'
      
     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '1'
      And the current branch in 'gitchef' should be 'deploy'

     When I check out 'master' in 'gitchef'
     Then the file named 'gitchef/what_revision_am_i' should contain '2'

     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '1'
      And the current branch in 'gitchef' should be 'deploy'

  Scenario: Clone a git repo with a revision, check out a different tag and fix it
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-revision'
      
     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '1'
      And the current branch in 'gitchef' should be 'deploy'

     When I check out 'master' in 'gitchef'
     Then the file named 'gitchef/what_revision_am_i' should contain '2'

     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '1'
      And the current branch in 'gitchef' should be 'deploy'

  Scenario: Clone a git repo with the checkout action, and avoid picking up a new change, ever.
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-checkout'
      
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'gitchef/.git/config' should exist
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I change the file named 'gitchef/what_revision_am_i' to 'foo'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'foo'

     When I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'foo'

  Scenario: Clone a git repo with the export action, and avoid picking up a new change, ever.
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-export'
      
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'gitchef/.git/config' should not exist
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I change the file named 'gitchef/what_revision_am_i' to 'foo'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'foo'

     When I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'foo'

  Scenario: Clone a git repo in merge mode, change the branch, change a file, add a file, and do the sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-merge'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/another_file' to 'This is local stuff'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I create a file named 'gitchef/yet_another_file' containing 'More stuff'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/another_file' should contain 'This is local stuff'
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And the file named 'gitchef/yet_another_file' should contain 'More stuff'

  Scenario: Clone a git repo in merge mode, commit a new file locally, and do the sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-merge'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I create a file named 'gitchef/completely_new_file' containing 'Totally awesome stuff'
      And I git add the file named 'completely_new_file' in 'gitchef'
      And I commit everything in 'gitchef' with the message 'Yay what a super revision'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/completely_new_file' should not exist
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And there should not be a commit with the message 'Yay what a super revision' in the commit logs for 'gitchef'

  Scenario: Clone a git repo in merge mode, change a file on the branch and on disk, and watch chef-client fail
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-merge'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/what_revision_am_i' to 'billions and billions'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '1'
      And the file named 'gitchef/what_revision_am_i' should contain 'billions and billions'

  Scenario: Clone a git repo in hard (default) mode, change the branch, change a file, add a file, and do the sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/another_file' to 'This is local stuff'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I create a file named 'gitchef/yet_another_file' containing 'More stuff'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/another_file' should contain 'This is another file'
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And the file named 'gitchef/yet_another_file' should contain 'More stuff'

  Scenario: Clone a git repo in hard (default) mode, commit a new file locally, and do the sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I create a file named 'gitchef/completely_new_file' containing 'Totally awesome stuff'
      And I git add the file named 'completely_new_file' in 'gitchef'
      And I commit everything in 'gitchef' with the message 'Yay what a super revision'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/completely_new_file' should not exist
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And there should not be a commit with the message 'Yay what a super revision' in the commit logs for 'gitchef'

  Scenario: Clone a git repo in hard (default) mode, change a file on the branch and on disk, and watch chef-client overwrite the change
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/what_revision_am_i' to 'billions and billions'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '3'

  Scenario: Clone a git repo in clean mode, change the branch, change a file, add a file, and do the sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-clean'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/another_file' to 'This is local stuff'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I create a file named 'gitchef/yet_another_file' containing 'More stuff'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/another_file' should contain 'This is another file'
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And the file named 'gitchef/yet_another_file' should not exist

  Scenario: Clone a git repo in clean mode, commit a new file locally, and do the sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-clean'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I create a file named 'gitchef/completely_new_file' containing 'Totally awesome stuff'
      And I git add the file named 'completely_new_file' in 'gitchef'
      And I commit everything in 'gitchef' with the message 'Yay what a super revision'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/completely_new_file' should not exist
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And there should not be a commit with the message 'Yay what a super revision' in the commit logs for 'gitchef'

  Scenario: Clone a git repo in clean mode, change a file on the branch and on disk, and watch chef-client overwrite the change
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-clean'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/what_revision_am_i' to 'billions and billions'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '3'

  Scenario: Clone a git repo in rebase mode, change a file in the remote, change and add unstaged files locally, and watch chef-client fail
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-rebase'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I change the file named 'gitchef/another_file' to 'This is local stuff'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I create a file named 'gitchef/yet_another_file' containing 'More stuff'
      And I run the chef-client again
     Then the run should exit '1'
      And the file named 'gitchef/another_file' should contain 'This is local stuff'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the file named 'gitchef/yet_another_file' should contain 'More stuff'

  Scenario: Clone a git repo in rebase mode, commit a new file locally, and do the sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-rebase'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'

     When I create a file named 'gitchef/completely_new_file' containing 'Totally awesome stuff'
      And I git add the file named 'completely_new_file' in 'gitchef'
      And I commit everything in 'gitchef' with the message 'Yay what a super revision'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/completely_new_file' should contain 'Totally awesome stuff'
      And the file named 'gitchef/what_revision_am_i' should contain '3'
      And there should be a commit with the message 'Yay what a super revision' in the commit logs for 'gitchef'

  Scenario: Clone a git repo in rebase mode, change a file on the branch and on disk, and watch chef-client fail
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-local-changes-rebase'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/what_revision_am_i' to 'billions and billions'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '1'
      And the file named 'gitchef/what_revision_am_i' should contain 'billions and billions'

  Scenario: Clone a git repo in development mode and do a no-op sync
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-development-mode'
      
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'gitchef/.git/config' should exist
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'master'

     When I run the chef-client again
     Then the run should exit '0'
      And a file named 'gitchef/.git/config' should exist
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'master'

  Scenario: Clone a git repo in development mode, change a file in the remote, change and add unstaged files locally, and watch chef-client fail
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-development-mode'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/another_file' to 'This is local stuff'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I create a file named 'gitchef/yet_another_file' containing 'More stuff'
      And I run the chef-client again
     Then the run should exit '1'
      And the file named 'gitchef/another_file' should contain 'This is local stuff'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the file named 'gitchef/yet_another_file' should contain 'More stuff'

  Scenario: Clone a git repo in development mode, change a file on the branch and on disk, and watch chef-client fail
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-development-mode'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
 
     When I change the file named 'gitchef/what_revision_am_i' to 'billions and billions'
      And I change the test git repo file named 'what_revision_am_i' to '3'
      And I run the chef-client again
     Then the run should exit '1'
      And the file named 'gitchef/what_revision_am_i' should contain 'billions and billions'

  Scenario: Clone a git repo, change the remote, and sync back
    Given a test git repo in the temp directory
      And a clone of the test git repo in 'other_repo'
      And a validated node
      And it includes the recipe 'scm::git'
      
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'gitchef/.git/config' should exist
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'deploy'
      And a branch named 'master' should exist in 'gitchef'

     When I change the test git repo file named 'what_revision_am_i' to 'foo'
      And I change the remote named 'origin' in 'gitchef' to point at 'other_repo'
      And I set the branch 'deploy' in 'gitchef' to track 'origin/master'
      And I pull in 'gitchef'
     Then the file named 'gitchef/what_revision_am_i' should contain '2'
      
     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain 'foo'

  Scenario: Clone a git repo in development mode, change the branch, and watch chef-client change it back
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git-development-mode'

     When I run the chef-client
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'master'
 
     When I check out 'foobranch' in 'gitchef'
     Then the file named 'gitchef/what_revision_am_i' should contain 'foo'
      And the current branch in 'gitchef' should be 'foobranch'
      And a branch named 'master' should exist in 'gitchef'

     When I run the chef-client again
     Then the run should exit '0'
      And the file named 'gitchef/what_revision_am_i' should contain '2'
      And the current branch in 'gitchef' should be 'master'
      And a branch named 'foobranch' should exist in 'gitchef'
