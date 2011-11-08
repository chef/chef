@api @api_nodes @nodes_update
Feature: Update a node
  In order to keep my node data up-to-date
  As a Developer
  I want to update my node via the API

  Scenario Outline: Update a node
    Given I am an administrator
      And a 'node' named 'webserver' exists
      And sending the method '<method>' to the 'node' with '<updated_value>'
     When I 'PUT' the 'node' to the path '/nodes/webserver'
     Then the inflated response should respond to '<method>' with '<updated_value>'
     When I 'GET' the path '/nodes/webserver'
     Then the inflated response should respond to '<method>' with '<updated_value>'

    Examples:
      | method           | updated_value                    |
      | run_list         | [ "recipe[one]", "recipe[two]" ] |
      | snakes           | really arent so bad              |
      | chef_environment | prod                             |

  @PL-493
  Scenario: Update a node to include a role which includes another role
    Given I am an administrator
      And a 'node' named 'webserver' exists
      And sending the method 'run_list' to the 'node' with '[ "role[role1_includes_role2]" ]'
     When I 'PUT' the 'node' to the path '/nodes/webserver'
     Then the inflated response should respond to 'run_list' with '[ "role[role1_includes_role2]" ]'
     When I 'GET' the path '/nodes/webserver'
     Then the inflated response should respond to 'run_list' with '[ "role[role1_includes_role2]" ]'

  Scenario: Update a node with a wrong private key
    Given I am an administrator
      And a 'node' named 'webserver' exists
      And sending the method 'run_list' to the 'node' with '[ "recipe[one]", "recipe[two]" ]'
     When I 'PUT' the 'node' to the path '/nodes/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @oss_only
  Scenario: Update a node when I am not an admin
    Given I am a non-admin
      And a 'node' named 'webserver' exists
      And sending the method 'run_list' to the 'node' with '[ "recipe[one]", "recipe[two]" ]'
     When I 'PUT' the 'node' to the path '/nodes/webserver'
     Then I should get a '403 "Forbidden"' exception

   Scenario: Update a node with a role that does not exist
     Given I am an administrator
       And a 'node' named 'webserver' exists
       And sending the method 'run_list' to the 'node' with '["role[not_exist]"]'
      When I 'PUT' the 'node' to the path '/nodes/webserver'
      Then the inflated response should respond to 'run_list' with '["role[not_exist]"]'
      When I 'GET' the path '/nodes/webserver'
      Then the inflated response should respond to 'run_list' with '["role[not_exist]"]'

