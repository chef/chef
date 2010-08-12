@api @api_environments @environments_create
Feature: Create an Environment via the REST API
  In order to create environments programatically
  As a developer
  I want to create environments via the REST API

  Scenario: Create a new environment
    Given I am an administrator
      And an 'environment' named 'cucumber'
     When I 'POST' the 'environment' to the path '/environments'
     Then the inflated responses key 'uri' should match 'http://.+/environments/cucumber'

  Scenario: Create an environment that already exists
    Given I am an administrator
      And an 'environment' named 'cucumber'
     When I 'POST' the 'environment' to the path '/environments'
      And I 'POST' the 'environment' to the path '/environments'
     Then I should get a '409 "Conflict"' exception

  Scenario: Create an environment with the wrong private key
    Given I am an administrator
      And an 'environment' named 'cucumber'
     When I 'POST' the 'environment' to the path '/environments' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Create an environment as a non-admin
    Given I am a non-admin
      And an 'environment' named 'cucumber'
     When I 'POST' the 'environment' to the path '/environments'
     Then I should get a '403 "Forbidden"' exception
