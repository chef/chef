@api @api_roles @roles_create
Feature: Create a role via the REST API
  In order to create roles programatically
  As a Devleoper
  I want to create roles via the REST API

  Scenario: Create a new role
    Given I am an administrator
      And a 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles'
      And the inflated responses key 'uri' should match '^http://.+/roles/webserver$'

  Scenario: Create a role that already exists
    Given I am an administrator
      And an 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles'
      And I 'POST' the 'role' to the path '/roles'
     Then I should get a '409 "Conflict"' exception

  Scenario: Create a new role with a wrong private key
    Given I am an administrator
      And a 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @oss_only
  Scenario: Create a new role as a non-admin
    Given I am a non-admin
      And a 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles'
     Then I should get a '403 "Forbidden"' exception

   Scenario: Create a role with a role that does not exist
     Given I am an administrator
       And an 'role' named 'role_not_exist'
      When I 'POST' the 'role' to the path '/roles'
      Then the inflated responses key 'uri' should match '^http://.+/roles/role_not_exist$'
      When I 'GET' the path '/roles/role_not_exist'
      Then the stringified response should be the stringified 'role'
