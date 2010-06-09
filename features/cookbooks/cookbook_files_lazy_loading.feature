
@cookbooks @cookbook_lazy_loading
Feature: Cookbook lazy loading
  In order to use the network efficiently and only download cookbook parts that are appropriate for the given Node
  As a Chef User
  I want to only download cookbook files and templates that are referred to in evaluated recipes
  
  Scenario: Include a cookbook containing 2 files, with a recipe that only references one via cookbook_file, and ensure that the second is not downloaded
   Given a validated node
     And it includes the recipe 'transfer_some_cookbook_files::default'
    When I run the chef-client with '-l debug'
    Then the run should exit '0'
    Then 'stdout' should have 'Storing updated cookbooks/transfer_some_cookbook_files/files/default/should_be_transferred.txt in the cache'
    Then 'stdout' should not have 'Storing updated cookbooks/transfer_some_cookbook_files/files/default/should_not_be_transferred.txt in the cache'
    
  Scenario: Include a cookbook containing 2 templates, with a recipe that only references one, and ensure that the second is not downloaded
   Given a validated node
     And it includes the recipe 'transfer_some_cookbook_files::default'
    When I run the chef-client with '-l debug'
    Then the run should exit '0'
    Then 'stdout' should have 'Storing updated cookbooks/transfer_some_cookbook_files/templates/default/should_be_transferred.erb in the cache'
    Then 'stdout' should not have 'Storing updated cookbooks/transfer_some_cookbook_files/templates/default/should_not_be_transferred.erb in the cache'


    

#@cookbooks @cookbook_metadata
#Feature: Cookbook Metadata 
#  In order to understand cookbooks without evaluating them 
#  As an Administrator 
#  I want to automatically generate metadata about cookbooks  
#
#  Scenario: Generate metadata for all cookbooks 
#    Given a local cookbook repository 
#     When I run the task to generate cookbook metadata 
#     Then the run should exit '0'
#      And 'stdout' should have 'Generating Metadata'
#      And a file named 'cookbooks_dir/cookbooks/metadata/metadata.json' should exist
#
#  Scenario: Generate metadata for a specific cookbook
#    Given a local cookbook repository
#     When I run the task to generate cookbook metadata for 'metadata'
#     Then the run should exit '0'
#      And 'stdout' should have 'Generating Metadata'
#      And a file named 'cookbooks_dir/cookbooks/metadata/metadata.json' should exist
      
