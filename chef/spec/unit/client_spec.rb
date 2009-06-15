#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Client, "initialize" do
  it "should create a new Chef::Client object" do
    Chef::Client.new.should be_kind_of(Chef::Client)
  end
end

describe Chef::Client, "run" do
  before(:each) do
    @client = Chef::Client.new
    to_stub = [
      :build_node,
      :register,
      :authenticate,
      :sync_library_files,
      :sync_attribute_files,
      :sync_definitions,
      :sync_recipes,
      :save_node,
      :save_node
    ]
    to_stub.each do |method|
      @client.stub!(method).and_return(true)
    end
    time = Time.now
    Time.stub!(:now).and_return(time)
    Chef::Compile.stub!(:new).and_return(mock("Chef::Compile", :null_object => true))
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
  
  it "should register for an openid" do
    @client.should_receive(:register).and_return(true)
    @client.run
  end
  
  it "should authenticate with the server" do
    @client.should_receive(:authenticate).and_return(true)
    @client.run
  end
  
  it "should synchronize definitions from the server" do
    @client.should_receive(:sync_definitions).and_return(true)
    @client.run
  end
  
  it "should synchronize recipes from the server" do
    @client.should_receive(:sync_recipes).and_return(true)
    @client.run
  end
  
  it "should synchronize and load library files from the server" do
    @client.should_receive(:sync_library_files).and_return(true)
    @client.run
  end
  
  it "should synchronize and load attribute files from the server" do
    @client.should_receive(:sync_attribute_files).and_return(true)
    @client.run
  end
  
  it "should save the nodes state on the server (twice!)" do
    @client.should_receive(:save_node).twice.and_return(true)
    @client.run
  end
  
  it "should converge the node to the proper state" do
    @client.should_receive(:converge).and_return(true)
    @client.run
  end

  it "should set the cookbook_path" do
    Chef::Config.should_receive('[]').with(:file_cache_path).
      and_return('/var/chef/cache/cookbooks')
    @client.run
  end
end

describe Chef::Client, "run_solo" do
  before(:each) do
    @client = Chef::Client.new
    @client.stub!(:build_node).and_return(true)
    Chef::Compile.stub!(:new).and_return(mock("Chef::Compile", :null_object => true))
    Chef::Runner.stub!(:new).and_return(mock("Chef::Runner", :null_object => true))
  end
  
  it "should start/stop the run timer" do
    time = Time.now
    Time.should_receive(:now).at_least(1).times.and_return(time)
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
    Chef::Config[:cookbook_path] = ['one', 'two']
    @client.run_solo
    Chef::Config[:cookbook_path].should eql(['one', 'two'])
  end
end

describe Chef::Client, "build_node" do
  before(:each) do
    @mock_facter_fqdn = mock("Facter FQDN")
    @mock_facter_fqdn.stub!(:value).and_return("foo.bar.com")
    @mock_facter_hostname = mock("Facter Hostname")
    @mock_facter_hostname.stub!(:value).and_return("foo")
    @mock_ohai = {
      :fqdn => "foo.bar.com",
      :hostname => "foo"
    }
    @mock_ohai.stub!(:all_plugins).and_return(true)
    Ohai::System.stub!(:new).and_return(@mock_ohai)
    @node = Chef::Node.new
    @mock_rest.stub!(:get_rest).and_return(@node)
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @client = Chef::Client.new
    Chef::Platform.stub!(:find_platform_and_version).and_return(["FooOS", "1.3.3.7"])
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
  before(:each) do
    @mock_rest = mock("Chef::REST", :new => true)
  end
end
