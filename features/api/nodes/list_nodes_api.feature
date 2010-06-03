@api @api_nodes @nodes_list
Feature: List nodes via the REST API
  In order to know what nodes exists programatically
  As a Developer
  I want to list all the nodes

  Scenario: List nodes when none have been created
    Given I am an administrator
      And there are no nodes 
     When I 'GET' the path '/nodes' 
     Then the inflated response should be an empty hash 

  Scenario: List nodes when one has been created
    Given I am an administrator
    Given a 'node' named 'webserver' exists
     When I 'GET' the path '/nodes'
     Then the inflated responses key 'webserver' should match '^http://.+/nodes/webserver$'
  
  Scenario: List nodes when two have been created
    Given I am an administrator
      And a 'node' named 'webserver' exists
      And a 'node' named 'dbserver' exists
     When I 'GET' the path '/nodes'
     Then the inflated response should be '2' items long
     Then the inflated responses key 'webserver' should match '^http://.+/nodes/webserver$'
     Then the inflated responses key 'dbserver' should match '^http://.+/nodes/dbserver$'

  Scenario: List nodes none have been created with a wrong private key
    Given I am an administrator
      And there are no cookbooks
     When I 'GET' the path '/nodes' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception
