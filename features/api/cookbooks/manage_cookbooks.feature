@api @cookbooks @tarballs
@manage_cookbook_tarballs

Feature: CRUD cookbook tarballs
  In order to manage cookbook data
  As a Developer
  I want to create, read, update, and delete cookbook tarballs

  # Creating a cookbook -- negative
@create_cookbook_negative
  Scenario: Should not be able to create a cookbook without a name parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'   
     When I create a cookbook with 'original cookbook tarball'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'missing required parameter: name'

  Scenario: Should not be able to create a cookbook with a blank name parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
     When I create a cookbook named '' with 'original cookbook tarball'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid parameter: name'

  Scenario: Should not be able to create a cookbook with invalid characters in the name parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
     When I create a cookbook named 'a+b' with 'original cookbook tarball'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid parameter: name'

  Scenario: Should not be able to create a cookbook with a name that already exists
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'file' named 'new cookbook tarball'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I create a cookbook named 'test_cookbook' with 'new cookbook tarball'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'cookbook already exists'

  Scenario: Should not be able to create a cookbook without a file parameter
    Given a 'registration' named 'bobo' exists
      And a 'hash' named 'nothing'
     When I create a cookbook named 'test_cookbook' with 'nothing'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'missing required parameter: file'

@manage_cookbook_tarballs_blank_file
  Scenario: Should not be able to create a cookbook with a blank file parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'blank file parameter'
     When I create a cookbook named 'test_cookbook' with 'blank file parameter'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid parameter: file must be a File'

@manage_cookbook_tarballs_string_file
  Scenario: Should not be able to create a cookbook with a string file parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'string file parameter'
     When I create a cookbook named 'test_cookbook' with 'string file parameter'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid parameter: file must be a File'

  Scenario: Should not be able to create a cookbook with an invalid tarball
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'not a tarball'
     When I create a cookbook named 'test_cookbook' with 'not a tarball'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid tarball'

  Scenario: Should not be able to create a cookbook with a tarball that does not contain a directory in the base with the same name as the cookbook
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'empty tarball'
     When I create a cookbook named 'test_cookbook' with 'empty tarball'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid tarball'

  # Creating a cookbook -- positive

@create_cookbook_positive
  Scenario: Create a cookbook and verify that it is in proceeding cookbooks listings
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
     When I create a cookbook named 'test_cookbook' with 'original cookbook tarball'
     Then the response code should be '201'
      And the 'Location' header should match 'http://[^/]+/cookbooks/test_cookbook'
      And the inflated responses key 'uri' should match 'http://[^/]+/cookbooks/test_cookbook'
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'test_cookbook' should exist

  # Downloading a cookbook -- negative

  Scenario: Downloading a non-existent cookbook should fail
    Given a 'registration' named 'bobo' exists
     When I download the 'non_existent' cookbook
     Then I should get a '404 "Not Found"' exception

  # Downloading a cookbook -- positive

  Scenario: After a cookbook is uploaded, it should be downloadable
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I download the 'test_cookbook' cookbook
     Then the response should be a valid tarball
      And the untarred response should include file 'test_cookbook/original'

  Scenario: Should be able to download a tarball for a cookbook that was placed on the file system (not uploaded through the API)
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
     And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     And I delete the cached tarball for 'test_cookbook'
     When I download the 'test_cookbook' cookbook
     Then the response should be a valid tarball
      And the untarred response should include file 'test_cookbook/original'

  # Updating a cookbook -- negative

  Scenario: Updating a non-existent cookbook should fail
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
     When I upload 'original cookbook tarball' to cookbook 'test_cookbook'
     Then the response code should be '404'

  Scenario: Should not be able to update a cookbook without a file parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'hash' named 'nothing'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I upload 'nothing' to cookbook 'test_cookbook'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'missing required parameter: file'

  Scenario: Should not be able to update a cookbook with a blank file parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'file' named 'blank file parameter'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I upload 'blank file parameter' to cookbook 'test_cookbook'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid parameter: file must be a File'

  Scenario: Should not be able to update a cookbook with a string file parameter
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'file' named 'string file parameter'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I upload 'string file parameter' to cookbook 'test_cookbook'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid parameter: file must be a File'

  Scenario: Should not be able to update a cookbook with an invalid tarball
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'file' named 'not a tarball'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I upload 'not a tarball' to cookbook 'test_cookbook'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid tarball'

  Scenario: Should not be able to update a cookbook with a tarball that does not contain a directory in the base with the same name as the cookbook
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'file' named 'empty tarball'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I upload 'empty tarball' to cookbook 'test_cookbook'
     Then the response code should be '400'
      And the inflated responses key 'error' should include 'invalid tarball'

  # Updating a cookbook -- positive

  Scenario: Should be able to update a cookbook and download the latest version afterwards
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'file' named 'new cookbook tarball'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I upload 'new cookbook tarball' to cookbook 'test_cookbook'
     Then the response code should be '200'
     When I download the 'test_cookbook' cookbook
      And the response should be a valid tarball
      And the untarred response should include file 'test_cookbook/new'

  # Deleting a cookbook -- negative

  Scenario: Deleting a non-existent cookbook should fail
    Given a 'registration' named 'bobo' exists
     When I delete cookbook 'non_existent'
     Then I should get a '404 "Not Found"' exception

  # Deleting a cookbook -- positive

  Scenario: Should be able to delete a cookbook and should be able to create a cookbook with the same name afterwards
    Given a 'registration' named 'bobo' exists
      And a 'file' named 'original cookbook tarball'
      And a 'file' named 'new cookbook tarball'
      And a cookbook named 'test_cookbook' is created with 'original cookbook tarball'
     When I delete cookbook 'test_cookbook'
     When I download the 'test_cookbook' cookbook
     Then I should get a '404 "Not Found"' exception
     When I create a cookbook named 'test_cookbook' with 'new cookbook tarball'
     Then the response code should be '201'
     When I download the 'test_cookbook' cookbook
      And the response should be a valid tarball
      And the untarred response should include file 'test_cookbook/new'
