@api @api_nodes @nodes_delete
Feature: Delete a node via the REST API 
  In order to remove a node 
  As a Developer 
  I want to delete a node via the REST API
  
  Scenario: Delete a node 
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver' exists
     When I 'DELETE' the path '/nodes/webserver'
     Then the inflated response should respond to 'name' with 'webserver' 

  Scenario: Delete a node that does not exist
    Given a 'registration' named 'bobo' exists
      And there are no nodes 
     When I 'DELETE' the path '/nodes/webserver'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete a node with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver' exists
     When I 'DELETE' the path '/nodes/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Delete a node as a when I am not an admin
    Given a 'registration' named 'not_admin' exists
      And a 'node' named 'webserver' exists
     When I 'DELETE' the path '/nodes/webserver'
     Then I should get a '401 "Unauthorized"' exception

