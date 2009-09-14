@api @api_clients @clients_show
Feature: Show a client via the REST API 
  In order to know what the details are for a client 
  As a Developer
  I want to show the details for a specific client
  
  Scenario: Show a client
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'isis' exists
     When I 'GET' the path '/clients/isis'
     Then the inflated responses key 'name' should match '^isis$'

  Scenario: Show a missing client
    Given a 'registration' named 'bobo' exists
      And there are no clients 
     When I 'GET' the path '/clients/frankenstein'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a client with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'isis' exists
     When I 'GET' the path '/clients/isis' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

