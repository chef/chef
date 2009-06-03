@api
Feature: Delete a Role via the REST API 
  In order to remove a role 
  As a Developer 
  I want to delete a role via the REST API
  
  Scenario: Delete a Role 
    Given a 'registration' named 'bobo' exists
      And a 'role' named 'webserver' exists
     When I authenticate as 'bobo'
      And I 'DELETE' the path '/roles/webserver'
     Then the inflated response should respond to 'name' with 'webserver' 

  Scenario: Delete a Role that does not exist
    Given a 'registration' named 'bobo' exists
      And there are no roles 
     When I authenticate as 'bobo'
     When I 'DELETE' the path '/roles/webserver'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete a Role without authenticating 
    Given a 'role' named 'webserver'
     When I 'DELETE' the path '/roles/webserver'
     Then I should get a '401 "Unauthorized"' exception

