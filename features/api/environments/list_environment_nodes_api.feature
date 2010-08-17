@api @api_environments @environments_node_list
Feature: List nodes by environments via the REST API
  In order to know what nodes are in an environment programmatically
  As a developer
  I want to list all the nodes in an environment via the REST API

  Scenario Outline: List nodes in an environment
    Given I am <user_type>
      And an 'environment' named 'production' exists
      And a 'node' named 'opsmaster' exists
     When I 'GET' the path '/environments/production/nodes'
     Then the inflated response should be '1' items long
      And the inflated responses key 'opsmaster' should match '^http://.+/nodes/opsmaster$'

    Examples:
      | user_type        |
      | an administrator |
      | a non-admin      |