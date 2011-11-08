@api @api_nodes @nodes_delete
Feature: Delete a node via the REST API
  In order to remove a node
  As a Developer
  I want to delete a node via the REST API

  Scenario: Delete a node
    Given I am an administrator
      And a 'node' named 'webserver' exists
     When I 'DELETE' the path '/nodes/webserver'
     Then the inflated response should respond to 'name' with 'webserver'

  Scenario: Delete a node that does not exist
    Given I am an administrator
      And there are no nodes
     When I 'DELETE' the path '/nodes/webserver'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete a node with a wrong private key
    Given I am an administrator
      And a 'node' named 'webserver' exists
     When I 'DELETE' the path '/nodes/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @oss_only
  Scenario: Delete a node as a when I am not an admin
    Given I am a non-admin
      And a 'node' named 'webserver' exists
     When I 'DELETE' the path '/nodes/webserver'
     Then I should get a '403 "Forbidden"' exception

