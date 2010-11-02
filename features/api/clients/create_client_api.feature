@api @api_clients @clients_create
Feature: Create a client via the REST API
  In order to create clients programatically 
  As a Devleoper
  I want to create clients via the REST API
  
  Scenario: Create a new client 
    Given I am an administrator
      And a 'client' named 'isis'
     When I create the client 
      And the inflated responses key 'uri' should match '^http://.+/clients/isis$'

  @oss_only
  Scenario: Create a new client as an admin
    Given I am an administrator
      And a 'client' named 'adminmonkey'
     When I create the client 
     When I 'GET' the path '/clients/adminmonkey' 
     Then the inflated response should respond to 'admin' with 'true'

  Scenario: Create a client that already exists
    Given I am an administrator
      And an 'client' named 'isis'
     When I create the client 
      And I create the client 
     Then I should get a '409 "Conflict"' exception

  Scenario: Create a new client with a wrong private key
    Given I am an administrator
      And a 'client' named 'isis'
     When I 'POST' the 'client' to the path '/clients' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Create a new client when you are not an admin
    Given I am a non-admin
      And a 'client' named 'isis'
     When I create the client 
     Then I should get a '403 "Forbidden"' exception

