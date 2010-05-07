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
 