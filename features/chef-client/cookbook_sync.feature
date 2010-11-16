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
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize_deps/recipes/default.rb in the cache.'

  Scenario: Removes files from the cache that are no longer needed 
    Given a validated node
      And it includes the recipe 'synchronize_deps'
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize_deps/recipes/default.rb in the cache.'
    Given we have an empty file named 'cookbooks/synchronize_deps/recipes/woot.rb' in the client cache
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Removing cookbooks/synchronize_deps/recipes/woot.rb from the cache'

  Scenario: Remove cookbooks that are no longer needed 
    Given a validated node
      And it includes the recipe 'synchronize_deps'
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Storing updated cookbooks/synchronize_deps/recipes/default.rb in the cache.'
    Given it includes no recipes
     When I run the chef-client with '-l info'
     Then the run should exit '0'
      And 'stdout' should have 'INFO: Removing cookbooks/synchronize_deps/recipes/default.rb from the cache; its cookbook is no longer needed on this client.'

  Scenario: Try to download a cookbook that depends on a non-existent cookbook
    Given I am an administrator
      And I fully upload a sandboxed cookbook named 'testcookbook_wrong_metadata' versioned '0.1.0' with 'testcookbook_wrong_metadata'
      And a validated node
      And it includes the recipe 'testcookbook_wrong_metadata'
     When I run the chef-client with '-l debug'
     Then the run should exit '1'
      And 'stdout' should have '412 Precondition Failed.*no_such_cookbook'

  Scenario: Utilise versioned dependencies
    Given this test is not pending
    Given I am an administrator
      And I fully upload a sandboxed cookbook named 'versions' versioned '0.2.0' with 'versions'
      And a validated node
      And it includes the recipe 'version_deps'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'thundercats_are_go.txt' should contain '1'

