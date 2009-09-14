@api @api_nodes @nodes_create
Feature: Create a node via the REST API
  In order to create nodes programatically 
  As a Devleoper
  I want to create nodes via the REST API
  
  Scenario: Create a new node 
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes' 
      And the inflated responses key 'uri' should match '^http://.+/nodes/webserver$'

  Scenario: Create a node that already exists
    Given a 'registration' named 'bobo' exists
      And an 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes' 
      And I 'POST' the 'node' to the path '/nodes' 
     Then I should get a '403 "Forbidden"' exception
  
  Scenario: Create a node with a wrong private key
    Given a 'registration' named 'bobo' exists
      And an 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Create a new node as when I am not an admin
    Given a 'registration' named 'not_admin' exists
      And a 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes' 
     Then I should get a '401 "Unauthorized"' exception
     
