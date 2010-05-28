@api @cookbooks
@manage_cookbook

# TODO: timh, 5-27-2010: It'd be nice if we could get the following kind of
# error checking, but it's not available when using Chef::REST
#   And the inflated responses key 'error' should include 'missing required parameter: name'

Feature: CRUD cookbooks
  In order to manage cookbook data
  As a Developer
  I want to create, read, update, and delete cookbook files and manifests

  @create_cookbook_negative

  Scenario: Should not be able to create a cookbook with the wrong name
    Given a 'registration' named 'bobo' exists
     When I create a versioned cookbook named 'foo' versioned '1.0.0' with 'testcookbook_valid'
     Then I should get a '400 "Bad Request"' exception

  Scenario: Should not be able to create a cookbook with the wrong version
    Given a 'registration' named 'bobo' exists
     When I create a versioned cookbook named 'testcookbook_valid' versioned '9.9.9' with 'testcookbook_valid'
     Then I should get a '400 "Bad Request"' exception

  Scenario: Should not be able to create a cookbook with missing name
    Given a 'registration' named 'bobo' exists
     When I create a versioned cookbook named '' versioned '9.9.9' with 'testcookbook_valid'
     Then I should get a '404 "Not Found"' exception

  Scenario: Should not be able to create a cookbook with missing name and version
    Given a 'registration' named 'bobo' exists
     When I create a versioned cookbook named '' versioned '' with 'testcookbook_valid'
     Then I should get a '404 "Not Found"' exception

  Scenario: Should not be able to create a cookbook with non-X.Y.Z version
    Given a 'registration' named 'bobo' exists
     When I create a versioned cookbook named 'testcookbook_valid' versioned '1.0' with 'testcookbook_valid'
     Then I should get a '404 "Not Found"' exception

  Scenario: Should not be able to create a cookbook if none of its contained files have been uploaded
    Given a 'registration' named 'bobo' exists
     When I create a versioned cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     Then I should get a '400 "Bad Request"' exception

  @create_cookbook_positive
  Scenario: Should be able to create a cookbook if its files have been uploaded
    Given a 'registration' named 'bobo' exists
     When I create a sandbox named 'sandbox1' for cookbook 'testcookbook_valid'
     Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
     Then I upload a file named 'metadata.json' from cookbook 'testcookbook_valid' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'metadata.rb' from cookbook 'testcookbook_valid' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'attributes/attributes.rb' from cookbook 'testcookbook_valid' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'recipes/default.rb' from cookbook 'testcookbook_valid' to the sandbox
     Then the response code should be '200'
     When I commit the sandbox
     Then I should not get an exception
     When I create a versioned cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     Then I should not get an exception
     
  @create_cookbook_positive
  Scenario: Cookbook successfully uploaded via sandbox should later be visible via /cookbooks, including its versions and metadata
    Given a 'registration' named 'bobo' exists
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should exist
     When I 'GET' the path '/cookbooks/testcookbook_valid'
     Then the inflated responses key 'testcookbook_valid' should exist
     Then the inflated responses key 'testcookbook_valid' item '0' should be '0.1.0'
     When I 'GET' the path '/cookbooks/testcookbook_valid/0.1.0'
     Then the inflated response should match '.*default.rb.*' as json

  # The sandbox is created missing 'metadata.json'. However, the cookbook's
  # manifest includes that file. We don't upload the file to the sandbox, but
  # the sandbox commits ok cuz it wasn't expecting that file. However, when we
  # try to create the cookbook, it should complain as its manifest wants that
  # file.
  @create_cookbook_negative
  Scenario: Should not be able to create a cookbook if it is missing one file
    Given a 'registration' named 'bobo' exists
     When I create a sandbox named 'sandbox1' for cookbook 'testcookbook_valid' minus files 'metadata.rb'
     Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
     Then I upload a file named 'metadata.json' from cookbook 'testcookbook_valid' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'attributes/attributes.rb' from cookbook 'testcookbook_valid' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'recipes/default.rb' from cookbook 'testcookbook_valid' to the sandbox
     Then the response code should be '200'
     When I commit the sandbox
     Then I should not get an exception
     When I create a versioned cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     Then I should get a '400 "Bad Request"' exception
  
  @create_cookbook_negative
  Scenario: Should not be able to create a cookbook if it has no metadata file
    Given a 'registration' named 'bobo' exists
     When I create a sandbox named 'sandbox1' for cookbook 'testcookbook_invalid_nometadata'
     Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
     Then I upload a file named 'attributes/attributes.rb' from cookbook 'testcookbook_invalid_nometadata' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'recipes/default.rb' from cookbook 'testcookbook_invalid_nometadata' to the sandbox
     Then the response code should be '200'
     When I commit the sandbox
     Then I should not get an exception
     When I create a versioned cookbook named 'testcookbook_invalid_nometadata' versioned '0.1.0' with 'testcookbook_invalid_nometadata'
     Then I should get a '400 "Bad Request"' exception
    
  #  update a cookbook with no files should fail
  @create_cookbook_negative
  Scenario: Should not be able to create a cookbook if it has no files and just metadata
    Given a 'registration' named 'bobo' exists
     When I create a sandbox named 'sandbox1' for cookbook 'testcookbook_invalid_empty_except_metadata'
     Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
     Then I upload a file named 'metadata.json' from cookbook 'testcookbook_invalid_empty_except_metadata' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'metadata.rb' from cookbook 'testcookbook_invalid_empty_except_metadata' to the sandbox
     Then the response code should be '200'
     When I commit the sandbox
     Then I should not get an exception
     When I create a versioned cookbook named 'testcookbook_invalid_empty_except_metadata' versioned '0.1.0' with 'testcookbook_invalid_empty'
     Then I should get a '400 "Bad Request"' exception

  # Downloading a cookbook -- negative

  @download_cookbook_negative
  Scenario: Listing versions for a non-existent cookbook should fail
    Given a 'registration' named 'bobo' exists
    When I 'GET' the path '/cookbooks/non_existent'
    Then I should get a '404 "Not Found"' exception
     
  @download_cookbook_negative
  Scenario: Retrieving a non-existent version for an existing cookbook should fail
    Given a 'registration' named 'bobo' exists
     Then I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I download the cookbook manifest for 'testcookbook_valid' version '9.9.9'
     Then I should get a '404 "Not Found"' exception
  
  # Downloading a cookbook -- positive
  @download_cookbook_positive
  Scenario: After a cookbook is uploaded, it should be downloadable
    Given a 'registration' named 'bobo' exists
     Then I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I download the cookbook manifest for 'testcookbook_valid' version '0.1.0'
     Then the downloaded cookbook manifest contents should match 'testcookbook_valid'

  Scenario: After a cookbook is uploaded, its contents should be downloadable
    Given a 'registration' named 'bobo' exists
     Then I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I download the cookbook manifest for 'testcookbook_valid' version '0.1.0'
     When I download the file 'metadata.json' from the downloaded cookbook manifest
     Then I should not get an exception
     When I download the file 'recipes/default.rb' from the downloaded cookbook manifest
     Then I should not get an exception

  @download_cookbook_positive
  Scenario: After uploading two versions of a cookbook, I should be able to retrieve files from either version
    Given a 'registration' named 'bobo' exists
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
     When I download the cookbook manifest for 'testcookbook_valid' version '0.1.0'
     Then I should not get an exception
     When I download the file 'recipes/default.rb' from the downloaded cookbook manifest
     Then the downloaded cookbook file contents should match the pattern '.*0.1.0.*'
     When I download the cookbook manifest for 'testcookbook_valid' version '0.2.0'
     Then I should not get an exception
     When I download the file 'recipes/default.rb' from the downloaded cookbook manifest
     Then the downloaded cookbook file contents should match the pattern '.*0.2.0.*'

  @delete_cookbook_positive @delete_cookbook_version_positive
  Scenario: After uploading two versions of a cookbook, then deleting the second, I should not be able to interact with the second but should be able to interact with the first
    Given a 'registration' named 'bobo' exists
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
    Given a 'registration' named 'bobo' exists
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.3.0'
     Then I should get a '404 "Not Found"' exception

  # Currently you cannot delete a cookbook by, e.g., DELETE /cookbooks/foo.
  # You delete all of its versions and then it disappears.     
  @delete_cookbook_positive
  Scenario: I should be able to delete a cookbook by deleting all of its versions
    Given a 'registration' named 'bobo' exists
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I 'DELETE' to the path '/cookbooks/testcookbook_valid/0.1.0'
     Then I should not get an exception
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should not exist
     When I 'GET' the path '/cookbooks/testcookbook_valid'
     Then I should get a '404 "Not Found"' exception
     
  @delete_cookbook_negative
  Scenario: I should not be able to delete a cookbook that doesn't exist'
    Given a 'registration' named 'bobo' exists
     When I 'DELETE' to the path '/cookbooks/testcookbook_nonexistent'
     Then I should get a '404 "Not Found"' exception
