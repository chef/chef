@client 
Feature: Synchronize cookbooks from the server
  In order to configure a system according to a centralized repository
  As an Administrator
  I want to synchronize cookbooks to the edge nodes

  Scenario: Synchronize specific cookbooks 
    Given a validated node
      And it includes the recipe 'synchronize'
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize/recipes/default.rb in the cache.'

  Scenario: Synchronize dependent cookbooks 
    Given a validated node
      And it includes the recipe 'synchronize_deps'
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize_deps/recipes/default.rb in the cache.'
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize/recipes/default.rb in the cache.'

