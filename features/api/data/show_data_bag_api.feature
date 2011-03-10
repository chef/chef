@api @data @api_data
Feature: Show a data_bag via the REST API
  In order to know what the details are for a data_bag
  As a Developer
  I want to show the details for a specific data_bag

  Scenario: Show a data_bag with no entries in it
    Given I am an administrator
      And a 'data_bag' named 'users' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data/users'
     Then the inflated response should be an empty hash

  Scenario: Show a data_bag with one entry in it
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data/users'
     Then the inflated responses key 'francis' should match '/data/users/francis'

  Scenario: Show a data_bag with two entries in it
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data/users'
     Then the inflated responses key 'francis' should match '/data/users/francis'
      And the inflated responses key 'axl_rose' should match '/data/users/axl_rose'

  Scenario: Show a missing data_bag
    Given I am an administrator
      And there are no data_bags
     When I authenticate as 'bobo'
      And I 'GET' the path '/data/users'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a data_bag without authenticating
    Given a 'data_bag' named 'users' exists
      And I 'GET' the path '/data/users'
     Then I should get a '400 "Bad Request"' exception

  Scenario: Show a data_bag with a wrong private key
    Given a 'registration' named 'bobo' exists
      And a 'data_bag' named 'users' exists
      And I 'GET' the path '/data/users' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception
