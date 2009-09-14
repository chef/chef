@api @api_roles @roles_create
Feature: Create a role via the REST API
  In order to create roles programatically 
  As a Devleoper
  I want to create roles via the REST API
  
  Scenario: Create a new role 
    Given a 'registration' named 'bobo' exists
      And a 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles' 
      And the inflated responses key 'uri' should match '^http://.+/roles/webserver$'

  Scenario: Create a role that already exists
    Given a 'registration' named 'bobo' exists
      And an 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles' 
      And I 'POST' the 'role' to the path '/roles' 
     Then I should get a '403 "Forbidden"' exception

  Scenario: Create a new role with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Create a new role as a non-admin
    Given a 'registration' named 'not_admin' exists
      And a 'role' named 'webserver'
     When I 'POST' the 'role' to the path '/roles' 
     Then I should get a '401 "Unauthorized"' exception

