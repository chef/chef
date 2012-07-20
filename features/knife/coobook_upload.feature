@knife @cookbook_upload @knife_cookbook_upload
Feature: Upload Cookbooks with Knife
  In order to use cookbooks I have written
  As a knife user
  I want to upload my cookbooks

  @regression
  Scenario: Uploading a new version updates the metadata on the server
    Given I am an administrator
     When I upload the 'version_updated' cookbook with knife
     When I 'GET' to the path '/cookbooks/version_updated'
     Then the inflated response should equal '{"version_updated"=>{"url"=>"http://127.0.0.1:4000/cookbooks/version_updated", "versions"=>[{"url"=>"http://127.0.0.1:4000/cookbooks/version_updated/2.0.0", "version"=>"2.0.0"}]}}'

  Scenario: Uploading a bad cookbook to the server from a repository with bad metadata.rb (CHEF-2923)
    Given I am an administrator
     When I upload the 'testcookbook_wrong_metadata_rb' cookbook with knife from a repository with bad metadata.rb
     Then knife should not succeed
 
  Scenario: Uploading a good cookbook to the server from a repository with bad metadata.rb (CHEF-2923)
    Given I am an administrator
     When I upload the 'testcookbook_good_metadata_rb' cookbook with knife from a repository with bad metadata.rb
     Then knife should succeed

