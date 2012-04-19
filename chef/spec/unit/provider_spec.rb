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

require 'spec_helper'

describe Chef::Provider do
  before(:each) do
    @cookbook_collection = Chef::CookbookCollection.new([])
    @node = Chef::Node.new
    @node.name "latte"
    @run_context = Chef::RunContext.new(@node, @cookbook_collection)
    @resource = Chef::Resource.new("funk", @run_context)
    @resource.cookbook_name = "a_delicious_pie"
    @provider = Chef::Provider.new(@resource, @run_context)
  end

  it "should store the resource passed to new as new_resource" do
    @provider.new_resource.should eql(@resource)
  end

  it "should store the node passed to new as node" do
    @provider.node.should eql(@node)
  end

  it "should have nil for current_resource by default" do
    @provider.current_resource.should eql(nil)
  end

  it "should return true for action_nothing" do
    @provider.action_nothing.should eql(true)
  end

  it "evals embedded recipes with a pristine resource collection" do
    @provider.run_context.instance_variable_set(:@resource_collection, "doesn't matter what this is")
    temporary_collection = nil
    snitch = Proc.new {temporary_collection = @run_context.resource_collection}
    @provider.send(:recipe_eval, &snitch)
    temporary_collection.should be_an_instance_of(Chef::ResourceCollection)
    @provider.run_context.instance_variable_get(:@resource_collection).should == "doesn't matter what this is"
  end

  it "does not re-load recipes when creating the temporary run context" do
    # we actually want to test that RunContext#load is never called, but we
    # can't stub all instances of an object with rspec's mocks. :/
    Chef::RunContext.stub!(:new).and_raise("not supposed to happen")
    snitch = Proc.new {temporary_collection = @run_context.resource_collection}
    @provider.send(:recipe_eval, &snitch)
  end
end
