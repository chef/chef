@api @api_nodes @nodes_show
Feature: Show a node via the REST API
  In order to know what the details are for a node
  As a Developer
  I want to show the details for a specific node

  Scenario: Show a node
    Given I am an administrator
      And a 'node' named 'webserver' exists
     When I 'GET' the path '/nodes/webserver'
     Then the inflated response should respond to 'name' with 'webserver'

  Scenario: Show a missing node
    Given I am an administrator
      And there are no nodes
     When I 'GET' the path '/nodes/bobo'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a node with a wrong private key
    Given I am an administrator
      And a 'node' named 'webserver' exists
     When I 'GET' the path '/nodes/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

