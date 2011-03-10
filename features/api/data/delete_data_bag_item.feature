@api @data @api_data @api_data_item
Feature: Delete a Data Bag Item via the REST API 
  In order to remove a Data Bag Item
  As a Developer 
  I want to delete a Data Bag Item via the REST API
  
  Scenario: Delete a Data Bag Item
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
     When I authenticate as 'bobo'
      And I 'DELETE' the path '/data/users/francis'
     Then the inflated responses key 'id' should match '^francis$'

  Scenario: Delete a Data Bag Item that does not exist
    Given I am an administrator
      And a 'data_bag' named 'users' exists
     When I authenticate as 'bobo'
     When I 'DELETE' the path '/data/users/francis'
     Then I should get a '404 "Not Found"' exception

  Scenario: Delete a Data Bag Item without authenticating 
    Given a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
     When I 'DELETE' the path '/data/users/francis'
     Then I should get a '400 "Bad Request"' exception

  @oss_only
  Scenario: Delete a Data Bag Item as a non-admin
    Given I am a non-admin
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
     When I 'DELETE' the path '/data/users/francis'
     Then I should get a '403 "Forbidden"' exception

