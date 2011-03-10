@api @data @api_data @api_data_item
Feature: Show a data_bag item via the REST API
  In order to know what the data is for an item in a data_bag
  As a Developer
  I want to retrieve an item from a data_bag

  Scenario: Show a data_bag item
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data/users/francis'
     Then the inflated responses key 'id' should match '^francis$'

  Scenario: Show a missing data_bag item
    Given I am an administrator
      And a 'data_bag' named 'users' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data/users/francis'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a data_bag item without authenticating
    Given a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And I 'GET' the path '/data/users/francis'
     Then I should get a '400 "Bad Request"' exception

  Scenario: Show a data_bag item with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
     When I 'GET' the path '/data/users/francis' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception


