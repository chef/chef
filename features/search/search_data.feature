@search
Feature: Search Data 
  In order to access information about my infrastructure 
  As a Developer
  I want to search the data 

  Scenario: Search the user index
    Given a validated node
      And it includes the recipe 'search::search_data'
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And a file named 'francis' should exist
      And a file named 'axl_rose' should exist

  Scenario: Search the user index without a block
    Given a validated node
      And it includes the recipe 'search::search_data_noblock'
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'francis' should exist
      And a file named 'axl_rose' should exist

  Scenario: Search the user index without a block, with manual paging
    Given a validated node
      And it includes the recipe 'search::search_data_manual'
      And a 'data_bag' named 'users' exists
      And a 'data_bag_item' named 'francis' exists
      And a 'data_bag_item' named 'axl_rose' exists
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'francis' should exist
      And a file named 'axl_rose' should exist

