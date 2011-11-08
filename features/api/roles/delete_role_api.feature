@api @api_roles @roles_delete
Feature: Delete a Role via the REST API
  In order to remove a role
  As a Developer
  I want to delete a role via the REST API

  Scenario: Delete a Role
    Given I am an administrator
      And a 'role' named 'webserver' exists
     When I 'DELETE' the path '/roles/webserver'
     Then the inflated response should respond to 'name' with 'webserver'

  Scenario: Delete a Role that does not exist
    Given I am an administrator
      And there are no roles
     When I 'DELETE' the path '/roles/webserver'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete a Role with a wrong private key
    Given I am an administrator
      And a 'role' named 'webserver' exists
     When I 'DELETE' the path '/roles/webserver' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @oss_only
  Scenario: Delete a Role as a non-admin
    Given I am a non-admin
      And a 'role' named 'webserver' exists
     When I 'DELETE' the path '/roles/webserver'
     Then I should get a '403 "Forbidden"' exception

