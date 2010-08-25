@api @api_environments @environments_delete
Feature: Delete environments via the REST API
  In order to remove an environment
  As a developer
  I want to delete an environment via the REST API

  Scenario: Delete an environment
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
     When I 'DELETE' the path '/environments/cucumber'
     Then the inflated response should respond to 'name' with 'cucumber'

  Scenario: Delete an environment that does not exist
    Given I am an administrator
     When I 'DELETE' the path '/environments/graveyard'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete an environment with the wrong private key
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
     When I 'DELETE' the path '/environments/cucumber' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Delete an environment as a non-admin
    Given I am a non-admin
      And an 'environment' named 'cucumber' exists
     When I 'DELETE' the path '/environments/cucumber'
     Then I should get a '403 "Forbidden"' exception

  Scenario Outline: Delete the '_default' environment
    Given I am <user_type>
     When I 'DELETE' the path '/environments/_default'
     Then I should get a '<exception_type>' exception

  Examples:
    | user_type        | exception_type           |
    | an administrator | 405 "Method Not Allowed" |
    | a non-admin      | 403 "Forbidden"          |
