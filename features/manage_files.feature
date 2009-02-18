Feature: Manage Files
  In order to save time
  As a Developer
  I want to manage files declaratively
  
  Scenario: Create a file
    Given a validated node
      And it includes the recipe 'manage_files::create_a_file'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'create_a_file.txt' should exist
      
  Scenario: Set the owner of a created file
    Given a validated node
      And it includes the recipe 'manage_files::set_the_owner_of_a_created_file'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'create_a_file.txt' should exist
      
     
  Scenario: Delete a file
    Given a validated node
      And it includes the recipe 'manage_files::delete_a_file'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'create_a_file.txt' should not exist

  Scenario: Delete a file that already does not exist
    Given a validated node
      And it includes the recipe 'manage_files::delete_a_file_that_does_not_already_exist'
     When I run the chef-client
     Then the run should exit '1'
      And stdout should have 'Cannot delete file'
  
  Scenario: Touch a file
    Given a validated node
      And it includes the recipe 'manage_files::touch_a_file'
      And we have an empty file named 'touch_test.txt'
      And we have the atime/mtime of 'touch_test.txt'
     When I run the chef-client
     Then the run should exit '0'
      And the atime of 'touch_test.txt' should be different
      And the mtime of 'touch_test.txt' should be different