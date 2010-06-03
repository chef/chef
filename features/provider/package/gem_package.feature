@provider @package @rubygems
Feature: Gem package
  In order to manage software and applications that require ruby gem packages
  As an OpsDev
  I want to install upgrade and remove rubygems

  Scenario: Installing a gem that is not installed
    Given a validated node
      And it includes the recipe 'packages::gem_package'
      And the gems server is running
     When I run the chef-client
     Then the run should exit '0'
      And the gem 'chef-integration-test' version '0.1.0' should be installed

  Scenario: Installing a gem using only the gems api
    Given a validated node
      And it includes the recipe 'packages::install_gem_noshell'
      And the gems server is running
     When I run the chef-client
     Then the run should exit '0'
      And the gem 'chef-integration-test' version '0.1.0' should be installed

  Scenario: Upgrading a gem to a newer version
    Given a validated node
      And it includes the recipe 'packages::upgrade_gem_package'
      And the gems server is running
     When I run the chef-client
     Then the run should exit '0'
      And the gem 'chef-integration-test' version '0.1.0' should be installed
      And the gem 'chef-integration-test' version '0.1.1' should be installed

  Scenario: Upgrading a gem using only the gems api
     Given a validated node
       And it includes the recipe 'packages::upgrade_gem_noshell'
       And the gems server is running
      When I run the chef-client
      Then the run should exit '0'
       And the gem 'chef-integration-test' version '0.1.0' should be installed
       And the gem 'chef-integration-test' version '0.1.1' should be installed

  Scenario: Upgrading a gem manually by specifying a different version
    Given a validated node
      And it includes the recipe 'packages::manually_upgrade_gem_package'
      And the gems server is running
     When I run the chef-client
     Then the run should exit '0'
      And the gem 'chef-integration-test' version '0.1.0' should be installed
      And the gem 'chef-integration-test' version '0.1.1' should be installed
