Feature: Transfer Remote Files
  In order to easily manage many systems at once
  As a Developer
  I want to manage the contents of files remotely
  
  Scenario: Transfer a file from a cookbook
    Given a validated node
      And it includes the recipe 'transfer_remote_files::transfer_a_file_from_a_cookbook'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'transfer_a_file_from_a_cookbook.txt' should contain 'easy like sunday morning'
      
  Scenario: Should prefer the file for this specific host
    Given a validated node
      And it includes the recipe 'transfer_remote_files::should_prefer_the_file_for_this_specific_host'
      And the cookbook has a 'file' named 'host_specific.txt' in the 'host' specific directory
      And the cookbook has a 'file' named 'host_specific.txt' in the 'platform-version' specific directory
      And the cookbook has a 'file' named 'host_specific.txt' in the 'platform' specific directory
      And the cookbook has a 'file' named 'host_specific.txt' in the 'default' specific directory
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'host_specific.txt' should be from the 'host' specific directory

  Scenario: Should prefer the file for the correct platform version
    Given a validated node
      And it includes the recipe 'transfer_remote_files::should_prefer_the_file_for_this_specific_host'
      And the cookbook has a 'file' named 'host_specific.txt' in the 'platform-version' specific directory
      And the cookbook has a 'file' named 'host_specific.txt' in the 'platform' specific directory
      And the cookbook has a 'file' named 'host_specific.txt' in the 'default' specific directory
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'host_specific.txt' should be from the 'platform-version' specific directory
      
    Scenario: Should prefer the file for the correct platform
      Given a validated node
        And it includes the recipe 'transfer_remote_files::should_prefer_the_file_for_this_specific_host'
        And the cookbook has a 'file' named 'host_specific.txt' in the 'platform' specific directory
        And the cookbook has a 'file' named 'host_specific.txt' in the 'default' specific directory
       When I run the chef-client
       Then the run should exit '0'
        And a file named 'host_specific.txt' should be from the 'platform' specific directory
