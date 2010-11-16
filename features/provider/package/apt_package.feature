@provider @package @apt
Feature: Install apt Packages from the Filesystem
  In order to automate installation of software in apt repositories
  As a Sysadmin
  I want chef to install deb packages

  Scenario: Install an apt package using the package resource
    Given I am running on a debian compatible OS
      And my dpkg architecture is 'amd64'
      And the apt server is running
      And I have configured my apt sources for integration tests 
      And I have updated my apt cache
      And a validated node
      And it includes the recipe 'packages::install_apt_package'
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And the dpkg package 'chef-integration-test' should be installed


