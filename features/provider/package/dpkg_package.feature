@provider @package @dpkg
Feature: Install deb Packages from the Filesystem
  In order to automate installation of software distributed as deb packages
  As a Sysadmin
  I want chef to install deb packages

  Scenario: Install a deb package using the dpkg resource
    Given I am running on a debian compatible OS
      And my dpkg architecture is 'amd64'
      And the deb package 'chef-integration-test-1.0' is available
     When I run chef-solo with the 'packages::install_dpkg_package' recipe
     Then the run should exit '0'
      And the dpkg package 'chef-integration-test-1.0' should be installed


  
  
  
