@api @data @api_data
Feature: List data bags via the REST API
  In order to know what data bags exists programatically
  As a Developer
  I want to list all the data bags

  Scenario: List data bags when none have been created
    Given I am an administrator
      And there are no data bags
     When I authenticate as 'bobo'
      And I 'GET' the path '/data'
     Then the inflated response should be an empty hash

  Scenario: List data bags when one has been created
    Given I am an administrator
      And a 'data_bag' named 'users' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data'
     Then the inflated responses key 'users' should match '^http://.+/data/users$'

  Scenario: List data bags when two have been created
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag' named 'rubies' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/data'
     Then the inflated response should be '2' items long
      And the inflated responses key 'users' should match '^http://.+/data/users$'
      And the inflated responses key 'rubies' should match '^http://.+/data/rubies$'

  Scenario: List data bags when you are not authenticated
     When I 'GET' the path '/data'
     Then I should get a '400 "Bad Request"' exception

  Scenario: List data bags with the wrong key
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/data' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception


