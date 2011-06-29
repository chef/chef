@api @cookbooks @api_cookbooks_delete
@manage_cookbook

Feature: CRUD cookbooks
  In order to manage cookbook data
  As a Developer
  I want to delete cookbook versions

  @delete_cookbook_positive @delete_cookbook_version_positive
  Scenario: After uploading two versions of a cookbook, then deleting the second, I should not be able to interact with the second but should be able to interact with the first
    Given I am an administrator
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
     When I 'GET' to the path '/cookbooks/testcookbook_valid/0.2.0'
     Then I should not get an exception
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.2.0'
     When I 'GET' to the path '/cookbooks/testcookbook_valid'
     Then the inflated responses key 'testcookbook_valid' should exist
     Then the inflated responses key 'testcookbook_valid' should be '1' items long
     Then the inflated responses key 'testcookbook_valid' item '0' should be '0.1.0'
     When I 'GET' to the path '/cookbooks/testcookbook_valid/0.2.0'
     Then I should get a '404 "Not Found"' exception
     When I download the cookbook manifest for 'testcookbook_valid' version '0.1.0'
     Then I should not get an exception
     When I download the file 'recipes/default.rb' from the downloaded cookbook manifest
     Then the downloaded cookbook file contents should match the pattern '.*0.1.0.*'

  @delete_cookbook_negative @delete_cookbook_version_negative
  Scenario: I should not be able to delete a cookbook version that does not exist
    Given I am an administrator
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.3.0'
     Then I should get a '404 "Not Found"' exception

  # Currently you cannot delete a cookbook by, e.g., DELETE /cookbooks/foo.
  # You delete all of its versions and then it disappears.     
  @delete_cookbook_positive
  Scenario: I should be able to delete a cookbook by deleting all of its versions
    Given I am an administrator
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.1.0'
     Then I should not get an exception
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should not exist
     When I 'GET' the path '/cookbooks/testcookbook_valid'
     Then I should get a '404 "Not Found"' exception
     
  @delete_cookbook_negative
  Scenario: I should not be able to delete a cookbook that doesn't exist'
    Given I am an administrator
     When I 'DELETE' to the path '/cookbooks/testcookbook_nonexistent'
     Then I should get a '404 "Not Found"' exception

  @delete_cookbook_negative @cookbook_non_admin
  Scenario: I should not be able to delete cookbook if I am not an admin
    Given I am an administrator
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
    Given I am a non-admin
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.1.0'
     Then I should get a '403 "Forbidden"' exception
