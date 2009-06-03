@api
Feature: Create a node via the REST API
  In order to create nodes programatically 
  As a Devleoper
  I want to create nodes via the REST API
  
  Scenario: Create a new node 
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver'
     When I authenticate as 'bobo'
      And I 'POST' the 'node' to the path '/nodes' 
      And the inflated responses key 'uri' should match '^http://.+/nodes/webserver$'

  Scenario: Create a node that already exists
    Given a 'registration' named 'bobo' exists
      And an 'node' named 'webserver'
     When I authenticate as 'bobo'
      And I 'POST' the 'node' to the path '/nodes' 
      And I 'POST' the 'node' to the path '/nodes' 
     Then I should get a '403 "Forbidden"' exception

  Scenario: Create a new node without authenticating
    Given a 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes' 
     Then I should get a '401 "Unauthorized"' exception
