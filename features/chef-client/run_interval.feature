@client @client_run_interval
Feature: Run chef-client at periodic intervals 
  In order to ensure a system is always correctly configured 
  As an Administrator
  I want to run the chef-client repeatedly at an interval

  Scenario: Run the client at an interval
    Given a validated node
      And it includes the recipe 'run_interval'
     When I run the chef-client with '-l info -i 5' for '12' seconds
     Then the run should exit '2' 
      And 'INFO: Starting Chef Run' should appear on 'stdout' '2' times

