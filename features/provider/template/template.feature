@provider @template
Feature: Templates
  In order to easily manage many systems at once
  As a Developer
  I want to manage the contents of files programatically

  Scenario: Render a template from a cookbook
    Given a validated node
      And it includes the recipe 'template'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'template.txt' should contain 'sauce'

	Scenario: Render a template accessing the node directly
	    Given a validated node
	      And it includes the recipe 'template::render_node_attrs'
	     When I run the chef-client
	     Then the run should exit '0'
	      And a file named 'node.txt' should contain 'bawt is fujins bot'
	      And a file named 'node.txt' should contain 'cheers!'

# Read the JIRA ticket for the full story, but what we're testing is that the
# template resource executes correctly the second time it's run in the same
# chef process
	@regression @chef_1384
  Scenario: Render a template twice running as a daemon
    Given a validated node
      And it includes the recipe 'template::interval'
     When I run the chef-client for no more than '30' seconds
     Then the run should exit '108'
      And a file named 'template.txt' should contain 'two'
