require 'support/shared/integration/integration_helper'
require 'chef/knife/list'

describe 'knife list' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server "is empty" do
    it "knife list / returns all top level directories" do
      knife('list', '/').stdout.should == "/cookbooks
/data_bags
/environments
/roles
"
    end

    it "knife list -R / returns everything" do
      knife('list', '-R', '/').stdout.should == "/:
cookbooks
data_bags
environments
roles

/cookbooks:

/data_bags:

/environments:
_default.json

/roles:
"
    end
  end

  when_the_chef_server "has plenty of stuff in it" do
    client 'client1', {}
    client 'client2', {}
    cookbook 'cookbook1', '1.0.0', { 'metadata.rb' => '' }
    cookbook 'cookbook2', '1.0.1', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
    data_bag 'bag1', { 'item1' => {}, 'item2' => {} }
    data_bag 'bag2', { 'item1' => {}, 'item2' => {} }
    environment 'environment1', {}
    environment 'environment2', {}
    node 'node1', {}
    node 'node2', {}
    role 'role1', {}
    role 'role2', {}
    user 'user1', {}
    user 'user2', {}

    it "knife list / returns all top level directories" do
      knife('list', '/').stdout.should == "/cookbooks
/data_bags
/environments
/roles
"
    end

    it "knife list -R / returns everything" do
      knife('list', '-R', '/').stdout.should == "/:
cookbooks
data_bags
environments
roles

/cookbooks:
cookbook1
cookbook2

/cookbooks/cookbook1:
metadata.rb

/cookbooks/cookbook2:
metadata.rb
recipes

/cookbooks/cookbook2/recipes:
default.rb

/data_bags:
bag1
bag2

/data_bags/bag1:
item1.json
item2.json

/data_bags/bag2:
item1.json
item2.json

/environments:
_default.json
environment1.json
environment2.json

/roles:
role1.json
role2.json
"
    end
  end
end
