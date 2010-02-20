@api @api_clients @clients_create
Feature: Create a client via the REST API
  In order to create clients programatically 
  As a Devleoper
  I want to create clients via the REST API
  
  Scenario: Create a new client 
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'isis'
     When I 'POST' the 'client' to the path '/clients' 
      And the inflated responses key 'uri' should match '^http://.+/clients/isis$'

  Scenario: Create a new client as an admin
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'adminmonkey'
     When I 'POST' the 'client' to the path '/clients' 
     When I 'GET' the path '/clients/adminmonkey' 
     Then the inflated response should respond to 'admin' with 'true'

  Scenario: Create a client that already exists
    Given a 'registration' named 'bobo' exists
      And an 'client' named 'isis'
     When I 'POST' the 'client' to the path '/clients' 
      And I 'POST' the 'client' to the path '/clients' 
     Then I should get a '409 "Conflict"' exception

  Scenario: Create a new client with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'isis'
     When I 'POST' the 'client' to the path '/clients' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Create a new client when you are not an admin
    Given a 'registration' named 'not_admin' exists
      And a 'client' named 'isis'
     When I 'POST' the 'client' to the path '/clients' 
     Then I should get a '401 "Unauthorized"' exception

