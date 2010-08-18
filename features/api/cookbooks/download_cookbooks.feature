@api @cookbooks @api_cookbooks_download
@manage_cookbook

Feature: CRUD cookbooks
  In order to manage cookbook data
  As a Developer
  I want to download cookbook files and manifests

  # Downloading a cookbook -- positive
  @download_cookbook_positive
  Scenario: After a cookbook is uploaded, it should be downloadable
    Given I am an administrator
     Then I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I download the cookbook manifest for 'testcookbook_valid' version '0.1.0'
     Then the downloaded cookbook manifest contents should match 'testcookbook_valid'
  
  Scenario: After a cookbook is uploaded, its contents should be downloadable
    Given I am an administrator
     Then I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I download the cookbook manifest for 'testcookbook_valid' version '0.1.0'
     When I download the file 'metadata.json' from the downloaded cookbook manifest
     Then I should not get an exception
     When I download the file 'recipes/default.rb' from the downloaded cookbook manifest
     Then I should not get an exception
  
  @download_cookbook_positive
  Scenario: After uploading two versions of a cookbook, I should be able to retrieve files from either version
    Given I am an administrator
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
  
  @download_cookbook_negative
  Scenario: Retrieving a non-existent version for an existing cookbook should fail
    Given I am an administrator
     Then I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     When I download the cookbook manifest for 'testcookbook_valid' version '9.9.9'
     Then I should get a '404 "Not Found"' exception
  

