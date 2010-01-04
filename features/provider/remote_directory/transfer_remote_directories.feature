@provider @remote_directory
Feature: Transfer remote directories
  In order to install copies of many files to many hosts
  As an OpsDev
  I want to transfer directories from remote locations

	Scenario: Transfer a directory from a cookbook
		 Given a validated node
	     And it includes the recipe 'transfer_remote_directories::transfer_directory'
	    When I run the chef-client
	    Then the run should exit '0'
	     And a file named 'transfer_directory/foo.txt' should contain 'tyrantanic'
	     And a file named 'transfer_directory/bar.txt' should contain 'Space Manoeuvres stage 1'
	     And a file named 'transfer_directory/baz.txt' should contain 'micromega'
 


  
