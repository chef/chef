@api @api_environments @show_roles
Feature: Show a role in an environment via the REST API
  In order to know what the run list is for a Role in a specific environment
  As a Developer
  I want to show the run list for a specific Role in a specific environment

  Scenario: Show an environment specific run list and attribuets in a role
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And a 'role' named 'webserver' exists
     When I 'GET' the path '/environments/cucumber/roles/webserver'
     Then the inflated response should respond to 'run_list' with '["role[db]"]'
