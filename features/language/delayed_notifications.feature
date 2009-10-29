@language
Feature: Delayed Notifications
  In order to not impact the system we are configuring unduly
  As a developer
  I want to be able to trigger an action on a resource only at the end of a run
  
  Scenario: Notify a resource from a single source
    Given a validated node
      And it includes the recipe 'delayed_notifications::notify_a_resource_from_a_single_source'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'notified_file.txt' should exist
      
  Scenario: Notify a resource from multiple sources
    Given a validated node
      And it includes the recipe 'delayed_notifications::notify_a_resource_from_multiple_sources'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'notified_file.txt' should contain 'bob dylan' only '1' time
  
  Scenario: Notify different resources for different actions
    Given a validated node
      And it includes the recipe 'delayed_notifications::notify_different_resources_for_different_actions'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'notified_file_2.txt' should exist
      And a file named 'notified_file_3.txt' should exist
  
