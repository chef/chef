@provider @provider_execute
Feature: Run Commands 
  In order to utilize the plethora of useful command line utilities 
  As a Developer
  I want to execute commands from within chef 

  Scenario: Execute a command
    Given a validated node
      And it includes the recipe 'execute_commands'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'mastodon_rocks' should exist
      
  Scenario: Execute a command with umask value 777
    Given a validated node
      And it includes the recipe 'execute_commands::umask'
     When I run the chef-client
     Then the run should exit '0'
      And '/mastodon_rocks_umask' should exist and raise error when copying

  Scenario: Execute a command with client logging to file
    Given a validated node
      And it includes the recipe 'execute_commands'
     When I run the chef-client with logging to the file 'silly-monkey.log'
     Then the run should exit '0'
      And a file named 'mastodon_rocks' should exist

  Scenario: Execute a command with more than 4k of output
    Given a validated node
      And it includes the recipe 'execute_commands::4k'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'execute-4k.txt' should exist

  Scenario: Execute a command at the debug log level
    Given a validated node
      And it includes the recipe 'execute_commands::debug'
     When I run the chef-client at log level 'debug'
     Then the run should exit '0'
      And 'stdout' should have 'DEBUG: Executing ruby -e .puts "whats up"; STDERR.puts "doc!".'
      And 'stdout' should have 'DEBUG: ---- Begin output of ruby -e .puts "whats up"; STDERR.puts "doc!". ----'
      And 'stdout' should have 'DEBUG: STDOUT: whats up'
      And 'stdout' should have 'DEBUG: STDERR: doc!'
      And 'stdout' should have 'DEBUG: ---- End output of ruby -e .puts "whats up"; STDERR.puts "doc!". ----'
      And 'stdout' should have 'DEBUG: Ran ruby -e .puts "whats up"; STDERR.puts "doc!". returned 0'
