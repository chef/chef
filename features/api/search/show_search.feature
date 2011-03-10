@api @data @api_search @api_search_show
Feature: Search data via the REST API
  In order to know about objects in the system
  As a Developer
  I want to search the objects

  Scenario: Search for objects when none have been created
    Given I am an administrator
      And a 'data_bag' named 'users' exists
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/users'
     Then the inflated responses key 'rows' should be '0' items long
      And the inflated responses key 'start' should be the integer '0'
      And the inflated responses key 'total' should be the integer '0'

  Scenario: Search for objects when one has been created
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/users'
     Then a 'Chef::DataBagItem' with id 'francis' should be in the search result
      And there should be '1' total search results

  Scenario: Search for objects when two have been created
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/users'
      Then a 'Chef::DataBagItem' with id 'francis' should be in the search result
      And a 'Chef::DataBagItem' with id 'axl_rose' should be in the search result
      And there should be '2' total search results

  @oss_only
  Scenario: Search for objects with a manual ascending sort order
    Given PL-540 is resolved in favor of not removing this feature
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/users?sort=id+asc'
     Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::DataBagItem'
      And the inflated responses key 'rows' item '0' key 'id' should be 'axl_rose'
      And the inflated responses key 'rows' item '1' should be a kind of 'Chef::DataBagItem'
      And the inflated responses key 'rows' item '1' key 'id' should be 'francis'
      And the inflated responses key 'start' should be the integer '0'
      And the inflated responses key 'total' should be the integer '2'

  @oss_only
  Scenario: Search for objects with a manual descending sort order
    Given PL-540 is resolved in favor of not removing this feature
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/users?sort=id+desc'
     Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::DataBagItem'
      And the inflated responses key 'rows' item '0' key 'id' should be 'francis'
      And the inflated responses key 'rows' item '1' should be a kind of 'Chef::DataBagItem'
      And the inflated responses key 'rows' item '1' key 'id' should be 'axl_rose'
      And the inflated responses key 'start' should be the integer '0'
      And the inflated responses key 'total' should be the integer '2'

  @oss_only
  Scenario: Search for objects and page through the results
    Given PL-540 is resolved in favor of not removing this feature
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/users?rows=1&sort=id+asc'
     Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::DataBagItem'
      And the inflated responses key 'rows' item '0' key 'id' should be 'axl_rose'
      And the inflated responses key 'rows' should be '1' items long
      And the inflated responses key 'start' should be the integer '0'
      And the inflated responses key 'total' should be the integer '2'
     When I 'GET' the path '/search/users?rows=1&start=1&sort=id+asc'
     Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::DataBagItem'
      And the inflated responses key 'rows' item '0' key 'id' should be 'francis'
      And the inflated responses key 'rows' should be '1' items long
      And the inflated responses key 'start' should be the integer '1'
      And the inflated responses key 'total' should be the integer '2'

  Scenario: Search for a subset of objects
    Given I am an administrator
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/users?q=id:axl_rose'
      Then a 'Chef::DataBagItem' with id 'axl_rose' should be in the search result
       And there should be '1' total search results

  Scenario: Search for a node
    Given I am an administrator
      And a 'node' named 'searchman' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/node?q=recipe:oracle'
     Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::Node'
      And the inflated responses key 'rows' item '0' key 'one' should be 'five'
      And the inflated responses key 'rows' item '0' key 'three' should be 'four'
      And the inflated responses key 'rows' item '0' key 'walking' should be 'tall'

  Scenario: Search for an environment
    Given I am an administrator
      And a 'environment' named 'cucumber' exists
      And I wait for '15' seconds
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/environment?q=name:cucumber'
     Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::Environment'
     And the inflated responses key 'rows' item '0' should respond to 'name' with 'cucumber'

  Scenario: Search for a client
    Given I am an administrator
      And a 'client' named 'isis' exists
      And the search index has been committed
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/client?q=*:*'
     Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::ApiClient'
      And the inflated responses key 'rows' item '0' should respond to 'name' with 'isis'

  Scenario: Search for a type of object that does not exist
    Given I am an administrator
     When I authenticate as 'bobo'
      And I 'GET' the path '/search/funkensteins'
     Then I should get a '404 "Not Found"' exception

  Scenario: Search for objects when you are not authenticated
     When I 'GET' the path '/search/users'
     Then I should get a '400 "Bad Request"' exception

