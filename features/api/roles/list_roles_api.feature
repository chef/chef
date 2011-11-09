@api @api_roles @roles_list
Feature: List roles via the REST API
  In order to know what roles exists programatically
  As a Developer
  I want to list all the roles

  Scenario: List roles when none have been created
    Given I am an administrator
      And there are no roles
     When I 'GET' the path '/roles'
     Then the inflated response should be '0' items long

  Scenario: List roles when one has been created
    Given I am an administrator
    Given a 'role' named 'webserver' exists
     When I 'GET' the path '/roles'
     Then the inflated responses key 'webserver' should match '^http://.+/roles/webserver$'

  Scenario: List roles when two have been created
    Given I am an administrator
      And a 'role' named 'webserver' exists
      And a 'role' named 'db' exists
     When I 'GET' the path '/roles'
#     Then the inflated responses key 'role_test' should match '^http://.+/roles/role_test$'
     Then the inflated responses key 'webserver' should match '^http://.+/roles/webserver$'
      And the inflated responses key 'db' should match '^http://.+/roles/db$'

  Scenario: List roles when none have been created with a wrong private key
    Given I am an administrator
      And there are no roles
     When I 'GET' the path '/roles' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

