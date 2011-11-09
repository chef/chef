@api @api_nodes @nodes_create
Feature: Create a node via the REST API
  In order to create nodes programatically
  As a Devleoper
  I want to create nodes via the REST API

  Scenario: Create a new node
    Given I am an administrator
      And a 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes'
      And the inflated responses key 'uri' should match '^http://.+/nodes/webserver$'

  Scenario: Create a node that already exists
    Given I am an administrator
      And an 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes'
      And I 'POST' the 'node' to the path '/nodes'
     Then I should get a '409 "Conflict"' exception

  Scenario: Create a node with a wrong private key
    Given I am an administrator
      And an 'node' named 'webserver'
     When I 'POST' the 'node' to the path '/nodes' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Create a node with a role that does not exist
    Given I am an administrator
      And an 'node' named 'role_not_exist'
     When I 'POST' the 'node' to the path '/nodes'
     Then the inflated responses key 'uri' should match '^http://.+/nodes/role_not_exist$'
     When I 'GET' the path '/nodes/role_not_exist'
     Then the stringified response should be the stringified 'node'

