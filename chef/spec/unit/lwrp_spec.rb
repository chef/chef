#
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

describe "override logging" do
  
  it "should log if attempting to load resource of same name" do
    Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "resources", "*"))].each do |file|
      Chef::Resource.build_from_file("lwrp", file)
    end

    Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp_override", "resources", "*"))].each do |file|
      Chef::Log.should_receive(:info).with(/overriding/)
      Chef::Resource.build_from_file("lwrp", file)
    end
  end

  it "should log if attempting to load provider of same name" do
    Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "providers", "*"))].each do |file|
      Chef::Provider.build_from_file("lwrp", file)
    end
    
    Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp_override", "providers", "*"))].each do |file|
      Chef::Log.should_receive(:info).with(/overriding/)
      Chef::Provider.build_from_file("lwrp", file)
    end
  end
  
end

describe "Light-weight Chef::Resource" do
  
  it "should load the resource into a properly-named class" do
    Chef::Resource.const_get("LwrpFoo").should be_kind_of(Class)
  end
  
  it "should set resource_name" do
    Chef::Resource::LwrpFoo.new("blah").resource_name.should eql(:lwrp_foo)
  end
  
  it "should add the specified actions to the allowed_actions array" do
    Chef::Resource::LwrpFoo.new("blah").allowed_actions.should include(:pass_buck, :twiddle_thumbs)
  end
  
  it "should create a method for each attribute" do
    Chef::Resource::LwrpFoo.new("blah").methods.map{ |m| m.to_sym}.should include(:monkey)
  end

  it "should build attribute methods that respect validation rules" do
    lambda { Chef::Resource::LwrpFoo.new("blah").monkey(42) }.should raise_error(ArgumentError)
  end
  
end

describe "Light-weight Chef::Provider" do
  before(:each) do
    node = Chef::Node.new
    node.platform(:ubuntu)
    node.platform_version('8.10')
    @run_context = Chef::RunContext.new(node, Chef::CookbookCollection.new({}))

    @runner = Chef::Runner.new(@run_context)
  end
  
  
  it "should load the provider into a properly-named class" do
    Chef::Provider.const_get("LwrpBuckPasser").should be_kind_of(Class)
  end
  
  it "should create a method for each attribute" do
    new_resource = mock("new resource", :null_object=>true)
    Chef::Provider::LwrpBuckPasser.new(nil, new_resource).methods.map{|m|m.to_sym}.should include(:action_pass_buck)
    Chef::Provider::LwrpThumbTwiddler.new(nil, new_resource).methods.map{|m|m.to_sym}.should include(:action_twiddle_thumbs)
  end

  it "should insert resources embedded in the provider into the middle of the resource collection" do
    injector = Chef::Resource::LwrpFoo.new("morpheus")
    injector.action(:pass_buck)
    injector.provider(:lwrp_buck_passer)
    dummy = Chef::Resource::ZenMaster.new("keanu reeves")
    dummy.provider(Chef::Provider::Easy)
    @run_context.resource_collection.insert(injector)
    @run_context.resource_collection.insert(dummy)

    Chef::Runner.new(@run_context).converge
    
    @run_context.resource_collection[0].should eql(injector)
    @run_context.resource_collection[1].name.should eql(:prepared_thumbs)
    @run_context.resource_collection[2].name.should eql(:twiddled_thumbs)
    @run_context.resource_collection[3].should eql(dummy)
  end
  
  it "should insert embedded resources from multiple providers, including from the last position, properly into the resource collection" do
    injector = Chef::Resource::LwrpFoo.new("morpheus")
    injector.action(:pass_buck)
    injector.provider(:lwrp_buck_passer)
    injector2 = Chef::Resource::LwrpBar.new("tank")
    injector2.action(:pass_buck)
    injector2.provider(:lwrp_buck_passer_2)
    dummy = Chef::Resource::ZenMaster.new("keanu reeves")
    dummy.provider(Chef::Provider::Easy)
    
    @run_context.resource_collection.insert(injector)
    @run_context.resource_collection.insert(dummy)
    @run_context.resource_collection.insert(injector2)
    
    Chef::Runner.new(@run_context).converge
    
    @run_context.resource_collection[0].should eql(injector)
    @run_context.resource_collection[1].name.should eql(:prepared_thumbs)
    @run_context.resource_collection[2].name.should eql(:twiddled_thumbs)
    @run_context.resource_collection[3].should eql(dummy)
    @run_context.resource_collection[4].should eql(injector2)
    @run_context.resource_collection[5].name.should eql(:prepared_eyes)
    @run_context.resource_collection[6].name.should eql(:dried_paint_watched)
  end

  it "should properly handle a new_resource reference" do
    resource = Chef::Resource::LwrpFoo.new("morpheus")
    resource.monkey("bob")
    resource.provider(:lwrp_monkey_name_printer)

    provider = @runner.build_provider(resource)
    provider.action_twiddle_thumbs

    provider.monkey_name.should == "my monkey's name is 'bob'"
  end

  it "should properly handle an embedded Resource accessing the enclosing Provider's scope" do

    resource = Chef::Resource::LwrpFoo.new("morpheus")
    resource.monkey("bob")
    resource.provider(:lwrp_embedded_resource_accesses_providers_scope)
    
    provider = @runner.build_provider(resource)
    provider.action_twiddle_thumbs

    provider.enclosed_resource.monkey.should == 'bob, the monkey'
  end
  
end
