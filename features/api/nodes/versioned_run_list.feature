@api @nodes @api_nodes

Feature: Versioned Run List
  In order to maintain multiple versions of a cookbook
  As a DevOps
  I want to create and use multiple versions of a cookbook

  @cookbook_dependencies
  Scenario: Unversioned run_list entries should automatically get the latest version
    Given I am an administrator
      And a validated node
      And it includes the recipe 'versions'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'thundercats_are_go.txt' should contain '1'

  @cookbook_dependencies
  Scenario: Uploading a newer version of a cookbook should cause it to be used
    Given I am an administrator
      And a validated node
      And it includes the recipe 'versions'
     When I fully upload a sandboxed cookbook named 'versions' versioned '0.2.0' with 'versions'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'thundercats_are_go.txt' should contain '2'

  @cookbook_dependencies
  Scenario: Providing a version number should cause that version of a cookbook to be used
    Given I am an administrator
      And a validated node
      And it includes the recipe 'versions' at version '0.1.0'
     When I fully upload a sandboxed cookbook named 'versions' versioned '0.2.0' with 'versions'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'thundercats_are_go.txt' should contain '1'



