@api @roles @roles_show
Feature: Show a role via the REST API 
  In order to know what the details are for a Role 
  As a Developer
  I want to show the details for a specific Role
  
  Scenario: Show a role
    Given a 'registration' named 'bobo' exists
      And a 'role' named 'webserver' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/roles/webserver'
     Then the inflated response should respond to 'name' with 'webserver'

  Scenario: Show a missing role
    Given a 'registration' named 'bobo' exists
      And there are no roles 
     When I authenticate as 'bobo'
      And I 'GET' the path '/roles/bobo'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a role without authenticating
    Given a 'role' named 'webserver' exists
      And I 'GET' the path '/roles/webserver'
     Then I should get a '401 "Unauthorized"' exception


