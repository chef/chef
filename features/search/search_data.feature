@search
Feature: Search Data 
  In order to access information about my infrastructure 
  As a Developer
  I want to search the data 

  Scenario: Search the node index
    Given a validated node
      And it includes the recipe 'search::search_data'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'search_one.txt' should exist
      And a file named 'search_two.txt' should exist

