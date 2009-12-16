@client @client-cookbook-sync
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

  Scenario: Removes files from the cache that are no longer needed 
    Given a validated node
      And it includes the recipe 'synchronize_deps'
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize_deps/recipes/default.rb in the cache.'
    Given we have an empty file named 'cookbooks/synchronize_deps/recipes/woot.rb' in the client cache
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Removing cookbooks/synchronize_deps/recipes/woot.rb from the cache; it is no longer on the server.'

  Scenario: Remove cookbooks that are no longer needed 
    Given a validated node
      And it includes the recipe 'synchronize_deps'
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize_deps/recipes/default.rb in the cache.'
    Given it includes no recipes
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Removing cookbooks/synchronize_deps/recipes/default.rb from the cache; it's cookbook is no longer needed on this client.'

