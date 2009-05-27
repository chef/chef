@api
Feature: Show a node via the REST API 
  In order to know what the details are for a node 
  As a Developer
  I want to show the details for a specific node
  
  Scenario: Show a node
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/nodes/webserver'
     Then the inflated response should respond to 'name' with 'webserver'

  Scenario: Show a missing node
    Given a 'registration' named 'bobo' exists
      And there are no nodes 
     When I authenticate as 'bobo'
      And I 'GET' the path '/nodes/bobo'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a node without authenticating
    Given a 'node' named 'webserver' exists
      And I 'GET' the path '/nodes/webserver'
     Then I should get a '401 "Unauthorized"' exception

