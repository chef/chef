@api @api_environments @environments_show
Feature: Show an environment via the REST API
  In order to know what the details for an environment are
  As a developer
  I want to show the details for a specific environment via the REST API

  Scenario Outline: Show an environment
    Given I am <user_type>
      And an 'environment' named 'cucumber' exists
     When I 'GET' the path '/environments/cucumber'
     Then the inflated response should respond to 'name' with 'cucumber'
      And the inflated response should respond to 'description' with 'I like to run tests'

    Examples:
      | user_type        |
      | an administrator |
      | a non-admin      |

  Scenario Outline: Show an environment that does not exist
    Given I am <user_type>
      And there are no environments
     When I 'GET' the path '/environments/cucumber'
     Then I should get a '404 "Not Found"' exception

    Examples:
      | user_type        |
      | an administrator |
      | a non-admin      |

  Scenario: Show an environment using the wrong private key
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And I 'GET' the path '/environments/cucumber' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception
