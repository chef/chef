@api @data @api_search @api_search_reindex
Feature: Trigger a reindex via the REST API
  In order to have a consistent index when all else fails
  As an OpsDev
  I want to rebuild the search index via the api

	Scenario: Ensure objects are inserted back into the index
	  Given I am an administrator
	    And a 'data_bag' named 'users' exists
	    And a 'data_bag_item' named 'francis' exists
	    And I wait for '15' seconds
	   When I 'POST' the 'data_bag' to the path '/search/reindex'
	    And I wait for '15' seconds
	    And I 'GET' the path '/search/users?sort=id+desc' 
	   Then the inflated responses key 'rows' item '0' should be a kind of 'Chef::DataBagItem'
	    And the inflated responses key 'rows' item '0' key 'id' should be 'francis'
	
  