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

require 'spec_helper'

Chef::Log.level = :debug

# Keeps track of what file got loaded in what order.
module LibraryLoadOrder
  extend self

  def load_order
    @load_order ||= []
  end

  def reset!
    @load_order = nil
  end

  def record(file)
    load_order << file
  end
end

describe Chef::RunContext do
  before(:each) do
    @chef_repo_path = File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "cookbooks"))
    cl = Chef::CookbookLoader.new(@chef_repo_path)
    cl.load_cookbooks
    @cookbook_collection = Chef::CookbookCollection.new(cl)
    @node = Chef::Node.new
    @node.run_list << "test" << "test::one" << "test::two"
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
  end

  it "has a cookbook collection" do
    @run_context.cookbook_collection.should == @cookbook_collection
  end

  it "has a node" do
    @run_context.node.should == @node
  end

  def fixture_cb_path(rel_path)
    File.expand_path(rel_path, @chef_repo_path)
  end

  # This test relies on fixture data in spec/data/run_context/cookbooks.
  # The behaviors described in these examples are affected by the metadata.rb
  # files and attributes files in those cookbooks.
  #
  # Attribute files in the fixture data will append their
  # "cookbook_name::attribute_file_name" to the node's `:attr_load_order`
  # attribute when loaded.
  describe "loading attribute files" do

    it "loads default.rb first, then other files in sort order" do
      @node.run_list("dependency1::default")
      @expansion = (@node.run_list.expand('_default'))

      @run_context.load_attributes_in_run_list_order(@expansion)
      @node[:attr_load_order].should == ["dependency1::default", "dependency1::aa_first", "dependency1::zz_last"]
    end

    it "loads dependencies before loading the depending cookbook's attributes" do
      # Also make sure that attributes aren't loaded twice if we have two
      # recipes from the same cookbook in the run list
      @node.run_list("test-with-deps::default", "test-with-deps::server")
      @expansion = (@node.run_list.expand('_default'))

      @run_context.load_attributes_in_run_list_order(@expansion)

      # dependencies are stored in a hash so therefore unordered, but they should be loaded in sort order
      @node[:attr_load_order].should == ["dependency1::default",
                                         "dependency1::aa_first",
                                         "dependency1::zz_last",
                                         "dependency2::default",
                                         "test-with-deps::default"]
    end

    it "does not follow infinite dependency loops" do
      @node.run_list("test-with-circular-deps::default")
      @expansion = (@node.run_list.expand('_default'))

      # Circular deps should not cause infinite loops
      @run_context.load_attributes_in_run_list_order(@expansion)

      @node[:attr_load_order].should == ["circular-dep2::default", "circular-dep1::default", "test-with-circular-deps::default"]
    end

    it "loads attributes from cookbooks that don't have a default.rb attribute file" do
      @node.run_list("no-default-attr::default.rb")
      @expansion = (@node.run_list.expand('_default'))

      #@run_context.should_receive(:load_attribute_file).with("no-default-attr", fixture_cb_path("no-default-attr/attributes/server.rb"))
      @run_context.load_attributes_in_run_list_order(@expansion)

      @node[:attr_load_order].should == ["no-default-attr::server"]
    end
  end

  describe "loading libraries" do
    before do
      LibraryLoadOrder.reset!
    end

    # One big test for everything. Individual behaviors are tested by the attribute code above.
    it "loads libraries in run list order" do
      @node.run_list("test-with-deps::default", "test-with-circular-deps::default")
      @expansion = (@node.run_list.expand('_default'))

      @run_context.load_libraries_in_run_list_order(@expansion)
      LibraryLoadOrder.load_order.should == ["dependency1", "dependency2", "test-with-deps", "circular-dep2", "circular-dep1", "test-with-circular-deps"]
    end
  end

  describe "loading LWRPs" do
    before do
      LibraryLoadOrder.reset!
    end

    # One big test for everything. Individual behaviors are tested by the attribute code above.
    it "loads LWRPs in run list order" do
      @node.run_list("test-with-deps::default", "test-with-circular-deps::default")
      @expansion = (@node.run_list.expand('_default'))

      @run_context.load_lwrps_in_run_list_order(@expansion)
      LibraryLoadOrder.load_order.should == ["dependency1-provider",
                                             "dependency1-resource",
                                             "dependency2-provider",
                                             "dependency2-resource",
                                             "test-with-deps-provider",
                                             "test-with-deps-resource",
                                             "circular-dep2-provider",
                                             "circular-dep2-resource",
                                             "circular-dep1-provider",
                                             "circular-dep1-resource",
                                             "test-with-circular-deps-provider",
                                             "test-with-circular-deps-resource"]
    end
  end

  describe "loading resource definitions" do
    before do
      LibraryLoadOrder.reset!
    end

    # One big test for all load order concerns. Individual behaviors are tested
    # by the attribute code above.
    it "loads resource definitions in run list order" do
      @node.run_list("test-with-deps::default", "test-with-circular-deps::default")
      @expansion = (@node.run_list.expand('_default'))

      @run_context.load_resource_definitions_in_run_list_order(@expansion)
      LibraryLoadOrder.load_order.should == ["dependency1-definition",
                                             "dependency2-definition",
                                             "test-with-deps-definition",
                                             "circular-dep2-definition",
                                             "circular-dep1-definition",
                                             "test-with-circular-deps-definition"]
    end

  end


  describe "after loading the cookbooks" do
    before do
      @run_context.load(@node.run_list.expand('_default'))
    end

    it "should load all the definitions in the cookbooks for this node" do
      @run_context.definitions.should have_key(:new_cat)
      @run_context.definitions.should have_key(:new_badger)
      @run_context.definitions.should have_key(:new_dog)
    end

    it "should load all the recipes specified for this node" do
      @run_context.resource_collection[0].to_s.should == "cat[einstein]"
      @run_context.resource_collection[1].to_s.should == "cat[loulou]"
      @run_context.resource_collection[2].to_s.should == "cat[birthday]"
      @run_context.resource_collection[3].to_s.should == "cat[peanut]"
      @run_context.resource_collection[4].to_s.should == "cat[fat peanut]"
    end

    it "loads all the attribute files in the cookbook collection" do
      @run_context.loaded_fully_qualified_attribute?("test", "george").should be_true
      @node[:george].should == "washington"
    end

    it "registers attributes files as loaded so they won't be reloaded" do
      # This test unfortunately is pretty tightly intertwined with the
      # implementation of how nodes load attribute files, but is the only
      # convenient way to test this behavior.
      @node.should_not_receive(:from_file)
      @node.include_attribute("test::george")
    end
  end

end
