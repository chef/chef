@api @api_clients @clients_delete
Feature: Delete a client via the REST API 
  In order to remove a client 
  As a Developer 
  I want to delete a client via the REST API
  
  Scenario: Delete a client 
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'isis' exists
     When I 'DELETE' the path '/clients/isis'
     Then the inflated responses key 'name' should match '^isis$' 

  Scenario: Delete a client that does not exist
    Given a 'registration' named 'bobo' exists
      And there are no clients 
     When I 'DELETE' the path '/clients/isis'
     Then I should get a '404 "Not Found"' exception
    
  Scenario: Delete a client with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'isis' exists
     When I 'DELETE' the path '/clients/isis' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Delete a client when you are not an admin
    Given a 'registration' named 'not_admin' exists
      And a 'client' named 'isis' exists
     When I 'DELETE' the path '/clients/isis'
     Then I should get a '401 "Unauthorized"' exception

