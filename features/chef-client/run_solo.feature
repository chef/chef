@client @client_run_solo
Feature: Run chef-solo
  In order to ensure a system is always correctly configured without chef-server
  As an Administrator
  I want to run the chef-solo

  Scenario: Run chef-solo without cookbooks should get error
     When I run chef-solo without cookbooks
     Then the run should exit '1'
      And 'stdout' should have 'FATAL: No cookbook found'

