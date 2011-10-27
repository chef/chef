@api @data @api_data
Feature: Create a data bag via the REST API
  In order to create data bags programatically
  As a Devleoper
  I want to create data bags via the REST API

  Scenario: Create a new data bag
    Given I am an administrator
      And a 'data_bag' named 'users'
     When I authenticate as 'bobo'
      And I 'POST' the 'data_bag' to the path '/data'
      And the inflated responses key 'uri' should match '^http://.+/data/users$'

  Scenario: Create a data bag that already exists
    Given I am an administrator
      And a 'data_bag' named 'users'
     When I authenticate as 'bobo'
      And I 'POST' the 'data_bag' to the path '/data'
      And I 'POST' the 'data_bag' to the path '/data'
     Then I should get a '409 "Conflict"' exception

  Scenario: Create a new data bag without authenticating
    Given a 'data_bag' named 'webserver'
     When I 'POST' the 'data_bag' to the path '/data'
     Then I should get a '400 "Bad Request"' exception

  @oss_only
  Scenario: Create a new data bag as a non-admin
    Given I am a non-admin
      And a 'data_bag' named 'users'
     When I 'POST' the 'data_bag' to the path '/data'
     Then I should get a '403 "Forbidden"' exception

