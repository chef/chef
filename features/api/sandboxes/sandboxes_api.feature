@api @sandboxes @sandbox @create_sandbox
Feature: Create a sandbox via the REST API 
  In order to have files available to be included in a cookbook
  As a Developer
  I want to upload files into a sandbox and commit the sandbox

  @positive  
  Scenario: Create a one-file sandbox
    Given I am an administrator
     When I create a sandbox named 'sandbox1'
     Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'

  @negative  
  Scenario: Create a one-file sandbox, but commit without uploading any files
    Given I am an administrator
     When I create a sandbox named 'sandbox1'
     Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
     When I commit the sandbox
     Then I should get a '400 "Bad Request"' exception

  @positive
  Scenario: Create a one-file sandbox, upload a file with an expected checksum, then commit
    Given I am an administrator
    When I create a sandbox named 'sandbox1'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then I upload a file named 'sandbox1_file1' to the sandbox
    Then the response code should be '200'
    When I commit the sandbox
    Then I should not get an exception

  @negative
  Scenario: Create a one-file sandbox, upload a file with an unexpected checksum, then commit
    Given I am an administrator
    When I create a sandbox named 'sandbox1'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then I upload a file named 'sandbox2_file1' to the sandbox
    Then I should get a '404 Resource Not Found' exception
    When I commit the sandbox
    Then I should get a '400 "Bad Request"' exception

  @negative
  Scenario: Create a one-file sandbox, upload a file with an expected checksum and one with an unexpected checksum, then commit
    Given I am an administrator
    When I create a sandbox named 'sandbox1'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then I upload a file named 'sandbox1_file1' to the sandbox
    Then the response code should be '200'
    Then I upload a file named 'sandbox2_file1' to the sandbox
    Then I should get a '404 Resource Not Found' exception
    When I commit the sandbox
    # commit works as we did upload the only correct file.
    Then I should not get an exception
 
  @negative @die
  Scenario: Create a one-file sandbox, upload a file to an expected checksum URL whose contents do not match that checksum, then commit
    Given I am an administrator
    When I create a sandbox named 'sandbox1'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then I upload a file named 'sandbox2_file1' using the checksum of 'sandbox1_file1' to the sandbox
    Then the response code should be '400'
    When I commit the sandbox
    Then I should get a '400 "Bad Request"' exception

# multiple file sandbox positive and 1/2 negative
  @positive
  Scenario: Create a two-file sandbox, upload two expected checksums, and commit
    Given I am an administrator
    When I create a sandbox named 'sandbox2'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then I upload a file named 'sandbox2_file1' to the sandbox
    Then the response code should be '200'
    Then I upload a file named 'sandbox2_file2' to the sandbox
    Then the response code should be '200'
    When I commit the sandbox
    Then I should not get an exception
    
  @negative
  Scenario: Create a two-file sandbox, upload one of the expected checksums, then commit
    Given I am an administrator
    When I create a sandbox named 'sandbox2'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then I upload a file named 'sandbox2_file1' to the sandbox
    Then the response code should be '200'
    When I commit the sandbox
    Then I should get a '400 "Bad Request"' exception

  @positive
  Scenario: Create a two-file sandbox, and check the needs_upload field is set for both checksums
    Given I am an administrator
    When I create a sandbox named 'sandbox2'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then the sandbox file 'sandbox2_file1' should need upload
    Then the sandbox file 'sandbox2_file2' should need upload

  @positive
  Scenario: Create a two-file sandbox, upload the files, then commit. Create the same sandbox again, and neither file should need_upload.
    Given I am an administrator
    When I create a sandbox named 'sandbox2'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then the sandbox file 'sandbox2_file1' should need upload
    Then the sandbox file 'sandbox2_file2' should need upload
    Then I upload a file named 'sandbox2_file1' to the sandbox
    Then the response code should be '200'
    Then I upload a file named 'sandbox2_file2' to the sandbox
    Then the response code should be '200'
    When I commit the sandbox
    Then I should not get an exception
    # create again.
    When I create a sandbox named 'sandbox2'
    Then the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'
    Then the sandbox file 'sandbox2_file1' should not need upload
    Then the sandbox file 'sandbox2_file2' should not need upload
