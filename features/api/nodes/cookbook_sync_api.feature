@api @nodes @cookbook_sync @api_nodes
Feature: Synchronize cookbooks to the edge
  In order to configure my nodes centrally
  As a Developer
  I want to synchronize the cookbooks from the server to the edge nodes

  Scenario: Retrieve the list of cookbook files to synchronize
    Given I am an administrator
      And a 'node' named 'sync' exists
     When I 'GET' the path '/nodes/sync/cookbooks'
      And the inflated responses key 'node_cookbook_sync' should exist
      And the inflated responses key 'node_cookbook_sync' should match '"recipes":' as json
      And the inflated responses key 'node_cookbook_sync' should match 'default.rb' as json
      And the inflated responses key 'node_cookbook_sync' should match '"definitions":' as json
      And the inflated responses key 'node_cookbook_sync' should match 'def_file.rb' as json
      And the inflated responses key 'node_cookbook_sync' should match '"libraries":' as json
      And the inflated responses key 'node_cookbook_sync' should match 'lib_file.rb' as json
      And the inflated responses key 'node_cookbook_sync' should match '"attributes":' as json
      And the inflated responses key 'node_cookbook_sync' should match 'attr_file.rb' as json

  @CHEF-1607
  Scenario: Retrieve the correct versions of cookbook files to sync, especially when they do not lexically sort
    Given I am an administrator
      And I upload multiple versions of the 'version_test' cookbook that do not lexically sort correctly
      And a 'node' named 'paradise' exists
     When I 'GET' the path '/nodes/paradise/cookbooks'
      And the inflated responses key 'version_test' should exist
      And the inflated responses key 'version_test' should match '"version":"0.10.0"' as json

  Scenario: Retrieve the list of cookbook files to syncronize when the node has a chef_environment
    Given I am an administrator
      And an 'environment' named 'cookbooks-0.1.0' exists
      And a 'node' named 'has_environment' exists
      And I upload multiple versions of the 'version_test' cookbook
     When I 'GET' the path '/nodes/has_environment/cookbooks'
     Then the inflated responses key 'version_test' should exist
      And the inflated responses key 'version_test' should match '"version":"0.1.0"' as json
    Given an 'environment' named 'cookbooks-0.1.1'
     When I 'PUT' the 'environment' to the path '/environments/cookbooks_test'
      And I 'GET' the path '/nodes/has_environment/cookbooks'
     Then the inflated responses key 'version_test' should exist
      And the inflated responses key 'version_test' should match '"version":"0.1.1"' as json
    Given an 'environment' named 'cookbooks-0.2.0'
     When I 'PUT' the 'environment' to the path '/environments/cookbooks_test'
      And I 'GET' the path '/nodes/has_environment/cookbooks'
     Then the inflated responses key 'version_test' should exist
      And the inflated responses key 'version_test' should match '"version":"0.2.0"' as json

  Scenario: Retrieve the list of cookbook files to synchronize with a wrong private key
    Given I am an administrator
      And a 'node' named 'sync' exists
     When I 'GET' the path '/nodes/sync/cookbooks' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @oss_only
  Scenario: Retrieve the list of cookbook files to synchronize as a non-admin
    Given I am a non-admin
      And a 'node' named 'sync' exists
     When I 'GET' the path '/nodes/sync/cookbooks'
     Then I should get a '403 "Forbidden"' exception

