@client
Feature: Run chef-client
  In order to ensure a system is always correctly configured
  As an Administrator
  I want to run the chef-client

  @empty_run_list
  Scenario: Run chef-client with an empty runlist should get a log warning the node has an empty run list
    Given a validated node with an empty runlist
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And 'stdout' should have 'has an empty run list.'

  @json_run_list
  Scenario: Run chef client with a run list from command line JSON attributes
     Given a validated node with an empty runlist
      When I run the chef-client with json attributes 'json_runlist_and_attrs'
      Then the run should exit '0'
       And a file named 'attribute_setting.txt' should contain 'from_json_file'
      When the node is retrieved from the API
      Then the inflated responses key 'attribute_priority_was' should match 'from_json_file'
