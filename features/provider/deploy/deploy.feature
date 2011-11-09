@provider @git @deploy @provider_deploy

Feature: Deploy
  In order to repeatably and reliably deploy web apps from a source repository from the comfort of chef
  As an OpsDev
  I want to have automated deployments

 Scenario: Deploy an app for the first time
   Given a validated node
     And it includes the recipe 'deploy'
     And I have a clone of the rails app in the data/tmp dir
     And that I have 'rails' '2.3.4' installed
     And that I have 'sqlite3-ruby' '1.2.5' installed
    When I run the chef-client
    Then the run should exit '0'
     And a file named 'deploy/shared' should exist
     And a file named 'deploy/shared/cached-copy/.git' should exist
     And a file named 'deploy/current/app' should exist
     And a file named 'deploy/current/config/database.yml' should exist
     And a file named 'deploy/current/db/production.sqlite3' should exist
     And a file named 'deploy/current/tmp/restart.txt' should exist

 Scenario: Deploy an app again
   Given a validated node
     And it includes the recipe 'deploy'
     And I have a clone of the rails app in the data/tmp dir
     And that I have 'rails' '2.3.4' installed
     And that I have 'sqlite3-ruby' '1.2.5' installed
    When I run the chef-client
     And I run the chef-client again
     And there should be 'two' releases

 Scenario: Deploy an app with custom layout attributes and callbacks
   Given a validated node
     And it includes the recipe 'deploy::callbacks'
     And I have a clone of the rails app in the data/tmp dir
     And that I have 'rails' '2.3.4' installed
     And that I have 'sqlite3-ruby' '1.2.5' installed
    When I run the chef-client
    Then the run should exit '0'
     And a callback named <callback_file> should exist
 	     |	before_migrate.rb	|
 	     |	before_symlink.rb	|
 	     |	before_restart.rb	|
 	     |	after_restart.rb	|
     And the callback named <callback> should have run
 	     |	before_restart.rb	|
 	     |	after_restart.rb	|

  Scenario: Deploy an app with resources inside the callbacks (embedded recipes)
    Given a validated node
      And it includes the recipe 'deploy::embedded_recipe_callbacks'
      And I have a clone of the rails app in the data/tmp dir
      And that I have 'rails' '2.3.4' installed
      And that I have 'sqlite3-ruby' '1.2.5' installed
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'deploy/current/app/before_symlink_was_here.txt' should exist
      And a file named 'deploy/current/tmp/restart.txt' should exist

  @chef-1816 @known_issue
  Scenario: Deploy twice and rollback once
    Given I haven't yet fixed CHEF-1816, this test should be pending
    Given a test git repo in the temp directory
      And a validated node
      And it includes the recipe 'deploy::deploy_commit1'
     When I run the chef-client
     Then the run should exit '0'
     Then there should be 'one' release
     When I remove 'recipe[deploy::deploy_commit1]' from the node's run list
      And I add 'deploy::deploy_commit2' to the node's run list
      And I run the chef-client
     Then the run should exit '0'
     Then there should be 'two' releases
     When I remove 'recipe[deploy::deploy_commit2]' from the node's run list
      And I add 'deploy::rollback_commit2' to the node's run list
      And I run the chef-client
     Then the run should exit '0'
     Then there should be 'one' release

  Scenario: Deploy an app twice using the idempotent revision deploy strategy
    Given a validated node
      And it includes the recipe 'deploy::revision_deploy'
      And I have a clone of the rails app in the data/tmp dir
      And that I have 'rails' '2.3.4' installed
      And that I have 'sqlite3-ruby' '1.2.5' installed
     When I run the chef-client
     And I run the chef-client at log level 'info'
     Then the run should exit '0'
      And there should be 'one' release
      And the second chef run should have skipped deployment
