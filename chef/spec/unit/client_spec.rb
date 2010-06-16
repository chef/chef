#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

require 'chef/run_context'
require 'chef/rest'

describe Chef::Client, "run" do
  it "should identify the node and run ohai, then register the client" do
    # Fake data to identify the node
    HOSTNAME = "hostname"
    FQDN = "hostname.example.org"
    Chef::Config[:node_name] = FQDN
    mock_ohai = {
      :fqdn => FQDN,
      :hostname => HOSTNAME,
      :platform => 'example-platform',
      :platform_version => 'example-platform',
      :data => {
      }
    }
    mock_ohai.stub!(:refresh_plugins).and_return(true)
    mock_ohai.stub!(:data).and_return(mock_ohai[:data])
    Ohai::System.stub!(:new).and_return(mock_ohai)

    # Fake node
    node = Chef::Node.new(HOSTNAME)
    node.name(FQDN)
    node[:platform] = "example-platform"
    node[:platform_version] = "example-platform-1.0"

    #node.stub!(:expand!)

    mock_chef_rest_for_node = OpenStruct.new({ })
    mock_chef_rest_for_client = OpenStruct.new({ })
    mock_couchdb = OpenStruct.new({ })

    Chef::CouchDB.stub(:new).and_return(mock_couchdb)

    # --Client.register
    #   Use a filename we're sure doesn't exist, so that the registration 
    #   code creates a new client.
    temp_client_key_file = Tempfile.new("chef_client_spec__client_key")
    temp_client_key_file.close
    FileUtils.rm(temp_client_key_file.path)
    Chef::Config[:client_key] = temp_client_key_file.path

    #   Client.register will register with the validation client name.
    Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).at_least(1).times.and_return(mock_chef_rest_for_node)
    Chef::REST.should_receive(:new).with(Chef::Config[:client_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key]).and_return(mock_chef_rest_for_client)
    mock_chef_rest_for_client.should_receive(:register).with(FQDN, Chef::Config[:client_key]).and_return(true)
    #   Client.register will then turn around create another
    #   Chef::REST object, this time with the client key it got from the
    #   previous step.
    Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url], FQDN, Chef::Config[:client_key]).and_return(mock_chef_rest_for_node)
    
    # --Client.build_node
    #   looks up the node, which we will return, then later saves it.
    mock_chef_rest_for_node.should_receive(:get_rest).with("nodes/#{FQDN}").and_return(node)
    mock_chef_rest_for_node.should_receive(:put_rest).with("nodes/#{FQDN}", node).at_least(3).times.and_return(node)

    # --Client.sync_cookbooks -- downloads the list of cookbooks to sync
    #
#     cookbook_manifests = Chef::CookbookLoader.new.inject({}){|memo, entry| memo[entry.first] = entry.second.generate_manifest ; memo }
#     pp cookbook_manifests
#     mock_chef_rest_for_node.should_receive(:get_rest).with("nodes/#{FQDN}/cookbooks").and_return(cookbook_manifests)
    
    # after run, check proper mutation of node
    # e.g., node.automatic_attrs[:platform], node.automatic_attrs[:platform_version]
    Chef::Config.node_path(File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "nodes")))
    Chef::Config.cookbook_path(File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "cookbooks")))
    client = Chef::Client.new
    client.stub!(:sync_cookbooks).and_return({})
    client.run
    
    
    # check that node has been filled in correctly
    node.automatic_attrs[:platform].should == "example-platform"
    node.automatic_attrs[:platform_version].should == "example-platform-1.0"
  end
end

if nil
describe Chef::Client, "run" do
  before(:each) do
    @client = Chef::Client.new
    to_stub = [
      :build_node,
      :register,
      :sync_cookbooks,
      :save_node,
      :converge,
      :run_report_handlers
    ]
    to_stub.each do |method|
      @client.stub!(method).and_return(true)
    end
    
    @mock_ohai = {
      :fqdn => "foo.bar.com",
      :hostname => "foo"
    }
    @mock_ohai.stub!(:refresh_plugins).and_return(true)
    Ohai::System.stub!(:new).and_return(@mock_ohai)
    
    @client.stub!(:run_ohai)
    @client.stub!(:ohai).and_return(@mock_ohai)
    
    @time = Time.now
    Time.stub!(:now).and_return(@time)
    Chef::RunContext.stub!(:new).and_return(mock("Chef::RunContext", :null_object => true))
    Chef::Runner.stub!(:new).and_return(mock("Chef::Runner", :null_object => true))
  end
  
  it "should start the run clock timer" do
    time = Time.now
    Time.should_receive(:now).twice.and_return(time)
    @client.run
  end

  it "should build the node" do
    @client.should_receive(:build_node).and_return(true)
    @client.run
  end
  
  it "should register for a client" do
    @client.should_receive(:register).and_return(true)
    @client.run
  end
  
  it "should synchronize the cookbooks from the server" do
    @client.should_receive(:sync_cookbooks).and_return(true)
    @client.run
  end
  
  it "should save the nodes state on the server (twice!)" do
    @client.should_receive(:save_node).exactly(2).times.and_return(true)
    @client.run
  end
  
  it "should converge the node to the proper state" do
    @client.should_receive(:converge).and_return(true)
    @client.run
  end
  
  it "should run report handlers" do
    @client.should_receive(:run_report_handlers).with(@time, @time, @time - @time)
    @client.run
  end

  it "should call exception handlers if an exception is raised" do
    @client.stub!(:save_node).and_raise("woot")
    @client.should_receive(:run_exception_handlers)
    lambda { @client.run }.should raise_error("woot")
  end

end

describe Chef::Client, "run_solo" do
  before(:each) do
    @client = Chef::Client.new
    [:run_ohai, :node_name, :build_node, :run_report_handlers].each do |method|
      @client.stub!(method).and_return(true)
    end
    @time = Time.now
    Time.stub!(:now).and_return(@time)
    Chef::RunContext.stub!(:new).and_return(mock("Chef::RunContext", :null_object => true))
    Chef::Runner.stub!(:new).and_return(mock("Chef::Runner", :null_object => true))
  end
  
  it "should start/stop the run timer" do
    time = Time.now
    Time.should_receive(:now).at_least(1).times.and_return(time)
    Chef::Config[:cookbook_path] = [File.join(CHEF_SPEC_DATA, "kitchen"), File.join(CHEF_SPEC_DATA, "cookbooks")]
    @client.run_solo
  end

  it "should build the node" do
    @client.should_receive(:build_node).and_return(true)
    @client.run_solo
  end
  
  it "should converge the node to the proper state" do
    @client.should_receive(:converge).and_return(true)
    @client.run_solo
  end

  it "should use the configured cookbook_path" do
    Chef::Config[:cookbook_path] = [File.join(CHEF_SPEC_DATA, "kitchen"), File.join(CHEF_SPEC_DATA, "cookbooks")]
    @client.run_solo
    Chef::Config[:cookbook_path].should eql([File.join(CHEF_SPEC_DATA, "kitchen"), File.join(CHEF_SPEC_DATA, "cookbooks")])
  end

  it "should run report handlers" do
    @client.should_receive(:run_report_handlers).with(@time, @time, @time - @time)
    @client.run_solo
  end

  it "should call exception handlers if an exception is raised" do
    @client.stub!(:converge).and_raise("woot")
    @client.should_receive(:run_exception_handlers)
    lambda { @client.run_solo }.should raise_error("woot")
  end
end

describe Chef::Client, "run_report_handlers" do
  before(:each) do
    @original_report_handlers = Chef::Config[:report_handlers]
    @handler = mock("Report Handler", :report => true)
    @client = Chef::Client.new
    Chef::Config[:report_handlers] << @handler
  end

  after(:each) do
    Chef::Config[:report_handlers] = @original_report_handlers 
  end

  it "should run report handlers" do
    @handler.should_receive(:report).and_return(true)
    @client.run_report_handlers(Time.now, Time.now, 0)
  end
end

describe Chef::Client, "run_exception_handlers" do
  before(:each) do
    @original_report_handlers = Chef::Config[:report_handlers]
    @handler = mock("Report Handler", :report => true)
    @client = Chef::Client.new
    @exception = Exception.new("woot")
    Chef::Config[:exception_handlers] << @handler
  end

  after(:each) do
    Chef::Config[:exception_handlers] = @original_report_handlers 
  end

  it "should run report handlers" do
    @handler.should_receive(:report).and_return(true)
    @client.run_exception_handlers(nil, nil, Time.now, Time.now, 0, @exception)
  end
end

describe Chef::Client, "build_node" do
  before(:each) do
    @mock_ohai = {
      :fqdn => "foo.bar.com",
      :hostname => "foo"
    }
    Chef::Config[:solo] = true
    @mock_ohai.stub!(:refresh_plugins).and_return(true)
    @mock_ohai.stub!(:data).and_return(@mock_ohai)
    Ohai::System.stub!(:new).and_return(@mock_ohai)
    @node = Chef::Node.new
    @mock_rest.stub!(:get_rest).and_return(@node)
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @client = Chef::Client.new
    Chef::Platform.stub!(:find_platform_and_version).and_return(["FooOS", "1.3.3.7"])
    Chef::Config[:node_name] = nil
  end
  
  it "should set the name equal to the FQDN" do
    @mock_rest.stub!(:get_rest).and_return(nil)
    @client.build_node
    @client.node.name.should eql("foo.bar.com")
  end
  
  it "should set the name equal to the hostname if FQDN is not available" do
    @mock_ohai[:fqdn] = nil
    @mock_rest.stub!(:get_rest).and_return(nil)
    @client.build_node
    @client.node.name.should eql("foo")
  end
  
  it "should add any json attributes to the node" do
    @client.json_attribs = { "one" => "two", "three" => "four" }
    @client.build_node
    @client.node.one.should eql("two")
    @client.node.three.should eql("four")
  end
  
  it "should allow you to set recipes from the json attributes" do
    @client.json_attribs = { "recipes" => [ "one", "two", "three" ]}
    @client.build_node
    @client.node.recipes.should == [ "one", "two", "three" ]
  end
  
  it "should allow you to set a run_list from the json attributes" do
    @client.json_attribs = { "run_list" => [ "role[base]", "recipe[chef::server]" ] }
    @client.build_node
    @client.node.run_list.should == [ "role[base]", "recipe[chef::server]" ]
  end
  
  it "should not add duplicate recipes from the json attributes" do
    @client.node = Chef::Node.new
    @client.node.recipes << "one"
    @client.json_attribs = { "recipes" => [ "one", "two", "three" ]}
    @client.build_node
    @client.node.recipes.should  == [ "one", "two", "three" ]
  end
  
  it "should set the tags attribute to an empty array if it is not already defined" do
    @client.build_node
    @client.node.tags.should eql([])
  end
  
  it "should not set the tags attribute to an empty array if it is already defined" do
    @client.node = @node
    @client.node[:tags] = [ "radiohead" ]
    @client.build_node
    @client.node.tags.should eql([ "radiohead" ])
  end
end

describe Chef::Client, "register" do
  before do
    @mock_rest = mock("Chef::REST", :null_object => true)
    @mock_rest.stub!(:get_rest).and_return(true)
    @mock_rest.stub!(:register).and_return(true)
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @chef_client = Chef::Client.new
    @chef_client.node_name = "testnode"
    @chef_client.stub!(:determine_node_name).and_return(true)
    File.stub!(:exists?).and_return(false)
  end
  
  describe "when the validation key is present" do
    before(:each) do
      File.stub!(:exists?).with(Chef::Config[:validation_key]).and_return(true)
    end

    it "should sign requests with the validation key" do
      Chef::REST.should_receive(:new).with(Chef::Config[:client_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key]).and_return(@mock_rest)
      @chef_client.register
    end

    it "should register for a new key-pair" do
      @mock_rest.should_receive(:register).with("testnode", Chef::Config[:client_key])
      @chef_client.register
    end
  end

  it "should setup the rest client to use the client key-pair" do
    Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).and_return(@mock_rest)
    @chef_client.register 
  end

end

describe Chef::Client, "run_ohai" do
  before do
    @mock_ohai = mock("Ohai::System", :null_object => true)
    @mock_ohai.stub!(:refresh_plugins).and_return(true)
    @mock_ohai.stub!(:refresh_plugins).and_return(true)
    Ohai::System.stub!(:new).and_return(@mock_ohai)
    @chef_client = Chef::Client.new
    @chef_client.ohai = @mock_ohai
  end

  it "refresh the plugins if ohai has already been run" do
    @mock_ohai.should_receive(:refresh_plugins).and_return(true)
    @chef_client.run_ohai
  end
end

end
