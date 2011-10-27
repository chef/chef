@provider @provider_directory
Feature: Create Directories
  In order to save time
  As a Developer
  I want to create directories

  Scenario: Create a directory
    Given a validated node
      And it includes the recipe 'directory_provider::create'
     When I run the chef-client
     Then the run should exit '0'
      And a directory named 'isis' should exist

  Scenario: Set the owner of a created directory
    Given a validated node
      And it includes the recipe 'directory_provider::create'
     When I run the chef-client
     Then the run should exit '0'
      And the directory named 'isis' should be owned by 'nobody'

  Scenario: Change the owner of a created directory
    Given a validated node
      And it includes the recipe 'directory_provider::owner_update'
     When I run the chef-client
     Then the run should exit '0'
      And the directory named 'isis' should be owned by 'root'

  Scenario: Set the accessibility of a created directory
    Given a validated node
      And it includes the recipe 'directory_provider::set_the_accessibility_of_a_created_directory'
     When I run the chef-client
     Then the run should exit '0'
      And the directory named 'octal0644' should have octal mode '0644'
      And the directory named 'octal2644' should have octal mode '2644'
      And the directory named 'decimal644' should have decimal mode '644'
      And the directory named 'decimal2644' should have decimal mode '2644'
      And the directory named 'string644' should have octal mode '644'
      And the directory named 'string0644' should have octal mode '0644'
      And the directory named 'string2644' should have octal mode '2644'


