@api @api_roles @roles_show
Feature: Show a role via the REST API 
  In order to know what the details are for a Role 
  As a Developer
  I want to show the details for a specific Role

  Scenario: Show a role
    Given I am an administrator
      And a 'role' named 'webserver' exists
     When I 'GET' the path '/roles/webserver'
     Then the inflated response should respond to 'name' with 'webserver'

  Scenario: Show a missing role
    Given I am an administrator
      And there are no roles 
     When I 'GET' the path '/roles/bobo'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a role with a wrong private key
    Given I am an administrator
      And a 'role' named 'webserver' exists
     When I 'GET' the path '/roles/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Show an environment specific run list and attribuets in a role
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And a 'role' named 'webserver' exists
     When I 'GET' the path '/roles/webserver/environments/cucumber'
     Then the inflated response should respond to 'run_list' with '["role[db]"]'

  Scenario: List environments in the role
    Given I am an administrator
      And a 'role' named 'webserver' exists
     When I 'GET' the path '/roles/webserver/environments'
     Then the inflated response should include 'cucumber'