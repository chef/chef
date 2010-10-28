@provider @git

Feature: Git
  In order to use files stored in git so I can deploy apps and use edge versions of software
  As a Developer
  I want to clone and update git repositories

@foo
  Scenario: Clone a git repo
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'scm::git'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'gitchef/.git' should exist
      And a file named 'gitchef/what_revision_am_i' should exist
  
  
  
