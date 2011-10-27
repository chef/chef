@api @api_roles @roles_update
Feature: Update a role
  In order to keep my role data up-to-date
  As a Developer
  I want to update my role via the API

  Scenario Outline: Update a role
    Given I am an administrator
      And a 'role' named 'webserver' exists
      And sending the method '<method>' to the 'role' with '<updated_value>'
     When I 'PUT' the 'role' to the path '/roles/webserver'
     Then the inflated response should respond to '<method>' with '<updated_value>'
     When I 'GET' the path '/roles/webserver'
     Then the inflated response should respond to '<method>' with '<updated_value>'

    Examples:
      | method              | updated_value                               |
      | description         | gorilla                                     |
      | run_list            | [ "recipe[one]", "recipe[two]", "role[a]" ] |
      | default_attributes  | { "a": "d" }                                |
      | override_attributes | { "c": "e" }                                |

  Scenario: Update a role with a wrong private key
    Given I am an administrator
      And a 'role' named 'webserver' exists
      And sending the method 'description' to the 'role' with 'gorilla'
     When I 'PUT' the 'role' to the path '/roles/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Update a role as a non-admin user
    Given I am a non-admin
      And a 'role' named 'webserver' exists
      And sending the method 'description' to the 'role' with 'gorilla'
     When I 'PUT' the 'role' to the path '/roles/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Update a node with a role that does not exist
    Given I am an administrator
      And a 'role' named 'webserver' exists
      And sending the method 'run_list' to the 'role' with '["role[not_exist]"]'
     When I 'PUT' the 'role' to the path '/roles/webserver'
     Then the inflated response should respond to 'run_list' with '["role[not_exist]"]'
     When I 'GET' the path '/roles/webserver'
     Then the inflated response should respond to 'run_list' with '["role[not_exist]"]'
