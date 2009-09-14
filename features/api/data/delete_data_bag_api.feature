@api @data @api_data @api_data_delete
Feature: Delete a Data Bag via the REST API 
  In order to remove a Data Bag 
  As a Developer 
  I want to delete a Data Bag via the REST API
  
  Scenario: Delete a Data Bag 
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
     When I authenticate as 'bobo'
      And I 'DELETE' the path '/data/users'
     Then the inflated response should respond to 'name' with 'users' 

  Scenario: Delete a Data Bag that does not exist
    Given a 'registration' named 'bobo' exists
      And there are no Data Bags 
     When I authenticate as 'bobo'
     When I 'DELETE' the path '/data/users'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete a Data Bag that has items in it
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
     When I authenticate as 'bobo'
      And I 'DELETE' the path '/data/users'
     Then the inflated response should respond to 'name' with 'users' 
      And the data_bag named 'users' should not have an item named 'francis' 

  Scenario: Delete a Data Bag without authenticating 
    Given a 'data_bag' named 'users' exists
     When I 'DELETE' the path '/data/users'
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Delete a Data Bag as a non-admin
    Given a 'registration' named 'not_admin' exists
      And a 'data_bag' named 'users' exists
     When I 'DELETE' the path '/data/users'
     Then I should get a '401 "Unauthorized"' exception

