@provider @provider_directory
Feature: Delete Directories 
  In order to save time 
  As a Developer
  I want to manage directories declaratively

  Scenario: Delete a directory 
    Given a validated node
      And it includes the recipe 'directory_provider::delete'
     When I run the chef-client at log level 'info'
     Then the run should exit '0'
      And a directory named 'particles' should not exist
      And 'stdout' should have 'INFO: Deleting directory'

  Scenario: Delete a directory that already does not exist
    Given a validated node
      And it includes the recipe 'directory_provider::delete_nonexistent'
     When I run the chef-client at log level 'info'
     Then the run should exit '0'
      And 'stdout' should not have 'INFO: Deleting directory'

