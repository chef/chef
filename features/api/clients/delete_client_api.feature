@api @api_clients @clients_delete
Feature: Delete a client via the REST API
  In order to remove a client
  As a Developer
  I want to delete a client via the REST API

  Scenario: Delete a client
    Given I am an administrator
      And a 'client' named 'isis' exists
     When I 'DELETE' the path '/clients/isis'
     Then the inflated responses key 'name' should match '^isis$'

  Scenario: Delete a client that does not exist
    Given I am an administrator
      And there are no clients
     When I 'DELETE' the path '/clients/isis'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete a client with a wrong private key
    Given I am an administrator
      And a 'client' named 'isis' exists
     When I 'DELETE' the path '/clients/isis' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @oss_only
  Scenario: Delete a client when you are not an admin
    Given I am a non-admin
      And a 'client' named 'isis' exists
     When I 'DELETE' the path '/clients/isis'
     Then I should get a '403 "Forbidden"' exception

