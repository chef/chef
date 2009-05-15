Feature: Delete a User
  In order to no longer use Opscode 
  As a User
  I want to delete my user account 
  
  Scenario: Delete a User
    Given a 'user' named 'bobo' exists
     When I 'DELETE' the path '/users/bobo'
     Then the response code should be '200'
      And the fields in the inflated response should match the 'user'

  Scenario: Delete a User that does not exist
    Given there are no users
     When I 'DELETE' the path '/users/bobo'
     Then the response code should be '404'
      And the inflated responses key 'error' should include 'Cannot find Username bobo'
