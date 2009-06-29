@api @roles @roles_list
Feature: List roles via the REST API
  In order to know what roles exists programatically
  As a Developer
  I want to list all the roles

  Scenario: List roles when none have been created
    Given a 'registration' named 'bobo' exists
      And there are no roles
     When I authenticate as 'bobo'
      And I 'GET' the path '/roles' 
     Then the inflated response should be an empty array

  Scenario: List roles when one has been created
    Given a 'registration' named 'bobo' exists
    Given a 'role' named 'webserver' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/roles'
     Then the inflated response should include '^http://.+/roles/webserver$'

  Scenario: List roles when two have been created
    Given a 'registration' named 'bobo' exists
      And a 'role' named 'webserver' exists
      And a 'role' named 'db' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/roles'
     Then the inflated response should be '3' items long
      And the inflated response should include '^http://.+/roles/role_test$'
      And the inflated response should include '^http://.+/roles/webserver$'
      And the inflated response should include '^http://.+/roles/db$'

  Scenario: List roles when you are not authenticated 
     When I 'GET' the path '/roles' 
     Then I should get a '401 "Unauthorized"' exception

