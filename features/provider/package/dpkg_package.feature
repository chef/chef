@provider @package @dpkg
Feature: Install deb Packages from the Filesystem
  In order to automate installation of software distributed as deb packages
  As a Sysadmin
  I want chef to install deb packages

  Scenario: Install a deb package using the dpkg resource
    Given I am running on a debian compatible OS
      And my dpkg architecture is 'amd64'
      And the deb package 'chef-integration-test_1.0' is available
      And a validated node
      And it includes the recipe 'packages::install_dpkg_package'
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And the dpkg package 'chef-integration-test' should be installed


  
  
  
