
@cookbooks @cookbook_cache_cleanup
Feature: Cookbook file downloads cache cleanup
  In order to use the network efficiently and only download files when they've changed
  As a Chef User
  I want to keep cookbook contents in the cache and only remove they're no longer needed

  Scenario: Include a cookbook which references a file and a template then run chef-client twice -- only the first run should download a file
   Given a validated node
     And it includes the recipe 'transfer_some_cookbook_files::default'
    When I run the chef-client with '-l debug'
    Then the run should exit '0'
    Then 'stdout' should have 'Storing updated cookbooks/transfer_some_cookbook_files/files/default/should_be_transferred.txt in the cache'
    Then 'stdout' should have 'Storing updated cookbooks/transfer_some_cookbook_files/templates/default/should_be_transferred.erb in the cache'
    When I run the chef-client with '-l debug'
    Then the run should exit '0'
    Then 'stdout' should not have 'Storing updated cookbooks/transfer_some_cookbook_files/files/default/should_be_transferred.txt in the cache'
    Then 'stdout' should not have 'Storing updated cookbooks/transfer_some_cookbook_files/templates/default/should_be_transferred.erb in the cache'

