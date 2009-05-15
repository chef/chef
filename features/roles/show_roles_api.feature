Feature: Show a User
  In order to know what the details are for a User
  As an Opscode Employee
  I want to show the details for a specific User 
  
  Scenario: Show a User
    Given a 'user' named 'bobo' exists
     When I 'GET' the path '/users/bobo'
     Then the response code should be '200'
      And the fields in the inflated response should match the 'user'

  Scenario: Show a missing User
    Given there are no users 
     When I 'GET' the path '/users/bobo'
     Then the response code should be '404'
      And the inflated responses key 'error' should include 'Cannot find Username bobo'

  Scenario: Showing a User should not include sensitive data
    Given a 'user' named 'bobo' exists
     When I 'GET' the path '/users/bobo'
     Then the response code should be '200'
      And the inflated responses key 'password' should not exist
      And the inflated responses key 'salt' should not exist

