@api @nodes @nodes_list
Feature: List nodes via the REST API
  In order to know what nodes exists programatically
  As a Developer
  I want to list all the nodes

  Scenario: List nodes when none have been created
    Given a 'registration' named 'bobo' exists
      And there are no nodes 
     When I authenticate as 'bobo'
      And I 'GET' the path '/nodes' 
     Then the inflated response should be an empty array

  Scenario: List nodes when one has been created
    Given a 'registration' named 'bobo' exists
    Given a 'node' named 'webserver' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/nodes'
     Then the inflated response should include '^http://.+/nodes/webserver$'

  Scenario: List nodes when two have been created
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver' exists
      And a 'node' named 'dbserver' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/nodes'
     Then the inflated response should be '2' items long
      And the inflated response should include '^http://.+/nodes/webserver$'
      And the inflated response should include '^http://.+/nodes/dbserver$'

  Scenario: List nodes when you are not authenticated 
     When I 'GET' the path '/nodes' 
     Then I should get a '401 "Unauthorized"' exception

