@api @data @api_data @api_data_item
Feature: Create a data bag item via the REST API
  In order to store an item in a data bag programatically 
  As a Devleoper
  I want to store data bag items via the REST API
  
  Scenario: Create a new data bag item
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis'
     When I authenticate as 'bobo'
      And I 'POST' the 'data_bag_item' to the path '/data/users' 
     Then the inflated responses key 'id' should match '^francis$'

  Scenario: Update a data bag item that already exists
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'francis_extra'
     When I authenticate as 'bobo'
      And I 'PUT' the 'data_bag_item' to the path '/data/users/francis' 
     Then the inflated responses key 'id' should match '^francis$'
      And the inflated responses key 'extra' should match '^majority$'

  Scenario: Create a new data bag without authenticating
    Given a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis'
     When I 'PUT' the 'data_bag_item' to the path '/data/users/francis' 
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Create a new data bag item as a non-admin
    Given a 'registration' named 'not_admin' exists
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis'
     When I 'PUT' the 'data_bag_item' to the path '/data/users/francis' 
     Then I should get a '401 "Unauthorized"' exception

