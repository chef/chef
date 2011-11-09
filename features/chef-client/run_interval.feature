@client @client_run_interval
Feature: Run chef-client at periodic intervals
  In order to ensure a system is always correctly configured
  As an Administrator
  I want to run the chef-client repeatedly at an interval

  Scenario: Run the client at an interval
    Given a validated node
      And it includes the recipe 'run_interval'
     When I run the chef-client with '-l info -i 1' for '12' seconds
     Then 'INFO: Starting Chef Run' should appear on 'stdout' '2' times

  Scenario: Run a background client for a few seconds
    Given a validated node
      And it includes the recipe 'run_interval'
     When I run the chef-client in the background with '-l info -i 2'
      And I stop the background chef-client after '10' seconds
     Then the background chef-client should not be running
      And 'INFO: Starting Chef Run' should appear on 'stdout' '2' times

  Scenario: Run a background client with the sync_library cookbook, update sync_library between intervals and ensure updated library is run
    Given I have restored the original 'sync_library' cookbook
      And a validated node
      And it includes the recipe 'sync_library'
     When I run the chef-client in the background with '-l info -i 2'
      And I update cookbook 'sync_library' from 'sync_library_updated' after the first run
      And I stop the background chef-client after '10' seconds
     Then 'INFO: First generation library' should appear on 'stdout' '1' times
      And 'INFO: Second generation library' should appear on 'stdout' '1' times
