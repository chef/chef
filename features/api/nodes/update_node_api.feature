@api @api_nodes @nodes_update
Feature: Update a node
  In order to keep my node data up-to-date
  As a Developer
  I want to update my node via the API 

  Scenario Outline: Update a node 
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver' exists
      And sending the method '<method>' to the 'node' with '<updated_value>'
     When I 'PUT' the 'node' to the path '/nodes/webserver' 
     Then the inflated response should respond to '<method>' with '<updated_value>' 
     When I 'GET' the path '/nodes/webserver'
     Then the inflated response should respond to '<method>' with '<updated_value>' 

    Examples:
      | method       | updated_value    |
      | run_list     | [ "recipe[one]", "recipe[two]" ] |
      | snakes       | really arent so bad | 
      

  Scenario: Update a node with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'node' named 'webserver' exists
      And sending the method 'run_list' to the 'node' with '[ "recipe[one]", "recipe[two]" ]'
     When I 'PUT' the 'node' to the path '/nodes/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Update a node when I am not an admin
    Given a 'registration' named 'not_admin' exists
      And a 'node' named 'webserver' exists
      And sending the method 'run_list' to the 'node' with '[ "recipe[one]", "recipe[two]" ]'
     When I 'PUT' the 'node' to the path '/nodes/webserver'
     Then I should get a '401 "Unauthorized"' exception

