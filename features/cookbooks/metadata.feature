@cookbooks @cookbook_metadata
Feature: Cookbook Metadata
  In order to understand cookbooks without evaluating them
  As an Administrator
  I want to automatically generate metadata about cookbooks

  Scenario: Generate metadata for all cookbooks
    Given a local cookbook repository
     When I run the task to generate cookbook metadata
     Then the run should exit '0'
      And 'stdout' should have 'Generating Metadata'
      And a file named 'cookbooks_dir/cookbooks/metadata/metadata.json' should exist

  Scenario: Generate metadata for a specific cookbook
    Given a local cookbook repository
     When I run the task to generate cookbook metadata for 'metadata'
     Then the run should exit '0'
      And 'stdout' should have 'Generating Metadata'
      And a file named 'cookbooks_dir/cookbooks/metadata/metadata.json' should exist

