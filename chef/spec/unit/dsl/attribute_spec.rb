

require 'spec_helper'
require 'chef/dsl/attribute'

describe Chef::DSL::Attribute do

  before do
    @node = Chef::Node.new

    @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    @cookbook_loader = Chef::CookbookLoader.new(@cookbook_repo)
    @cookbook_loader.load_cookbooks

    @cookbook_collection = Chef::CookbookCollection.new(@cookbook_loader.cookbooks_by_name)

    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @attribute = Chef::DSL::Attribute.new(@node, @run_context)
    @attribute.eval_attribute("openldap", "default")
    @attribute.eval_attribute("openldap", "smokey")
  end

  it "should eval attributes files in cookbooks" do
    @node.ldap_server.should eql("ops1prod")
    @node.ldap_basedn.should eql("dc=hjksolutions,dc=com")
    @node.ldap_replication_password.should eql("forsure")
    @node.smokey.should eql("robinson")
  end
end

