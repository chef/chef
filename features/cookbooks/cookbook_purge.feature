@cookbooks @cookbook_purge @manage_cookbook @checksum_purge
Feature: Purge Cookbook Files
  In order to remove files with sensitive information or force the system into a consistent state
  As a sysadmin
  I want to purge cookbooks and all associated state from the Chef server

  @api @oss_only
  Scenario: Purge a cookbook when its files are on disk
    Given I am an administrator
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.2.0?purge=true'
     Then I should not get an exception
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should not exist
      And the cookbook's files should have been deleted
      And the cookbook's checksums should be removed from couchdb

  @knife @oss_only
  Scenario: Purge a cookbook using knife when its files are on disk
    Given I am an administrator
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
     When I run knife 'cookbook delete testcookbook_valid --all --purge --yes'
     Then knife should succeed
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should not exist
      And the cookbook's files should have been deleted
      And the cookbook's checksums should be removed from couchdb

  @api @oss_only
  Scenario: Purge a cookbook when its files are not on disk
    Given I am an administrator
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
      And I delete the cookbook's on disk checksum files
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.2.0?purge=true'
     Then I should not get an exception
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should not exist
      And the cookbook's files should have been deleted
      And the cookbook's checksums should be removed from couchdb
  
  
  
  
