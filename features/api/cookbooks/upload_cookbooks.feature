@api @cookbooks @api_cookbooks_upload
@manage_cookbook

Feature: CRUD cookbooks
  In order to manage cookbook data
  As a Developer
  I want to create and upload cookbook files and manifests

  @create_cookbook_negative

  Scenario: Should not be able to create a cookbook with the wrong name
    Given I am an administrator
     When I create a versioned cookbook named 'foo' versioned '1.0.0' with 'testcookbook_valid'
     Then I should get a '400 "Bad Request"' exception

  Scenario: Should not be able to create a cookbook with the wrong version
    Given I am an administrator
     When I create a versioned cookbook named 'testcookbook_valid' versioned '9.9.9' with 'testcookbook_valid'
     Then I should get a '400 "Bad Request"' exception

  Scenario: Should not be able to create a cookbook with missing name
    Given I am an administrator
     When I create a versioned cookbook named '' versioned '9.9.9' with 'testcookbook_valid'
     Then I should get a '404 "Not Found"' exception

  Scenario: Should not be able to create a cookbook with missing name and version
    Given I am an administrator
     When I create a versioned cookbook named '' versioned '' with 'testcookbook_valid'
     Then I should get a '404 "Not Found"' exception

  Scenario: Should not be able to create a cookbook with non-X.Y.Z version
    Given I am an administrator
     When I create a versioned cookbook named 'testcookbook_valid' versioned '1.0' with 'testcookbook_valid'
     Then I should get a '404 "Not Found"' exception

  Scenario: Should not be able to create a cookbook if none of its contained files have been uploaded
    Given I am an administrator
     When I create a versioned cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     Then I should get a '400 "Bad Request"' exception

  @create_cookbook_positive
  Scenario: Should be able to create a cookbook if its files have been uploaded
    Given I am an administrator
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
    Given I am an administrator
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should exist
     When I 'GET' the path '/cookbooks/testcookbook_valid'
     Then the inflated responses key 'testcookbook_valid' should exist
     Then the inflated responses key 'testcookbook_valid' sub-key 'versions' item '0' sub-key 'version' should equal '0.1.0'
     When I 'GET' the path '/cookbooks/testcookbook_valid/0.1.0'
     Then the inflated response should match '.*default.rb.*' as json

  @create_multiple_cookbook_versions_positive
  Scenario: Multiple cookbook versions successfully uploaded are visible
    Given I am an administrator
      And I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
      And I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.2.0' with 'testcookbook_valid_v0.2.0'
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'testcookbook_valid' should exist
     When I 'GET' the path '/cookbooks/testcookbook_valid'
     Then the inflated responses key 'testcookbook_valid' should exist
      And the inflated responses key 'testcookbook_valid' sub-key 'versions' should be '2' items long
      And the inflated responses key 'testcookbook_valid' sub-key 'versions' item '0' sub-key 'version' should equal '0.2.0'
      And the inflated responses key 'testcookbook_valid' sub-key 'versions' item '1' sub-key 'version' should equal '0.1.0'

  @update_cookbook_version_metadata_positive
  Scenario: A successful cookbook version upload that changes the metadata is properly reflected
    Given I am an administrator
      And I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I 'GET' the path '/cookbooks/testcookbook_valid/0.1.0'
     Then the inflated response should be a kind of 'Chef::CookbookVersion'
      And the dependencies in its metadata should be an empty hash
     When I fully upload a sandboxed cookbook force-named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid_v0.1.0_with_different_dependencies'
     Then the inflated response should be a kind of 'Chef::CookbookVersion'
      And the metadata should include a dependency on 'aws'

  # The sandbox is created missing 'metadata.json'. However, the cookbook's
  # manifest includes that file. We don't upload the file to the sandbox, but
  # the sandbox commits ok cuz it wasn't expecting that file. However, when we
  # try to create the cookbook, it should complain as its manifest wants that
  # file.
  @create_cookbook_negative
  Scenario: Should not be able to create a cookbook if it is missing one file
    Given I am an administrator
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
    Given I am an administrator
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
    Given I am an administrator
     When I create a sandbox named 'sandbox1' for cookbook 'testcookbook_invalid_empty_except_metadata'
     Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
     Then I upload a file named 'metadata.json' from cookbook 'testcookbook_invalid_empty_except_metadata' to the sandbox
     Then the response code should be '200'
     Then I upload a file named 'metadata.rb' from cookbook 'testcookbook_invalid_empty_except_metadata' to the sandbox
     Then the response code should be '200'
     When I commit the sandbox
     Then I should not get an exception
     When I create a cookbook named 'testcookbook_invalid_empty_except_metadata' with only the metadata file
     Then I should get a '400 "Bad Request"' exception

  @freeze_cookbook_version
  Scenario: Create a frozen Cookbook Version
    Given I am an administrator
      And I have uploaded a frozen cookbook named 'testcookbook_valid' at version '0.1.0'
     When I 'GET' the path '/cookbooks/testcookbook_valid/0.1.0'
     Then the cookbook version document should be frozen

  @freeze_cookbook_version @overwrite_frozen_version
  Scenario: Cannot overwrite a frozen Cookbook Version
    Given I am an administrator
      And I have uploaded a frozen cookbook named 'testcookbook_valid' at version '0.1.0'
     When I upload a cookbook named 'testcookbook_valid' at version '0.1.0'
     Then I should get a '409 "Conflict"' exception
