#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

# These tests rely on fixture data in spec/data/run_context/cookbooks.
#
# Dependencies (circular or not) are specified by `depends` directives in the
# metadata of these cookbooks.
#
# Side effects used to verify the behavior are implemented as code in the various file types.
#
describe Chef::RunContext::CookbookCompiler do

  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:cookbook_loader) do
    cl = Chef::CookbookLoader.new(chef_repo_path)
    cl.load_cookbooks
    cl
  end

  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }

  let(:chef_repo_path) { File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "cookbooks")) }

  let(:cookbook_collection) { Chef::CookbookCollection.new(cookbook_loader) }

  # Lazy evaluation of `expansion` here is used to mutate the run list before expanding it
  let(:run_list_expansion) { node.run_list.expand('_default') }

  let(:compiler) do
    Chef::RunContext::CookbookCompiler.new(run_context, run_list_expansion, events)
  end


  describe "loading attribute files" do

    # Attribute files in the fixture data will append their
    # "cookbook_name::attribute_file_name" to the node's `:attr_load_order`
    # attribute when loaded.

    it "loads default.rb first, then other files in sort order" do
      node.run_list("dependency1::default")

      compiler.compile_attributes
      node[:attr_load_order].should == ["dependency1::default", "dependency1::aa_first", "dependency1::zz_last"]
    end

    it "loads dependencies before loading the depending cookbook's attributes" do
      # Also make sure that attributes aren't loaded twice if we have two
      # recipes from the same cookbook in the run list
      node.run_list("test-with-deps::default", "test-with-deps::server")

      compiler.compile_attributes

      # dependencies are stored in a hash so therefore unordered, but they should be loaded in sort order
      node[:attr_load_order].should == ["dependency1::default",
                                        "dependency1::aa_first",
                                        "dependency1::zz_last",
                                        "dependency2::default",
                                        "test-with-deps::default"]
    end

    it "does not follow infinite dependency loops" do
      node.run_list("test-with-circular-deps::default")

      # Circular deps should not cause infinite loops
      compiler.compile_attributes

      node[:attr_load_order].should == ["circular-dep2::default", "circular-dep1::default", "test-with-circular-deps::default"]
    end

    it "loads attributes from cookbooks that don't have a default.rb attribute file" do
      node.run_list("no-default-attr::default.rb")

      compiler.compile_attributes

      node[:attr_load_order].should == ["no-default-attr::server"]
    end
  end

  describe "loading libraries" do
    before do
      LibraryLoadOrder.reset!
    end

    # One big test for everything. Individual behaviors are tested by the attribute code above.
    it "loads libraries in run list order" do
      node.run_list("test-with-deps::default", "test-with-circular-deps::default")

      compiler.compile_libraries
      LibraryLoadOrder.load_order.should == ["dependency1", "dependency2", "test-with-deps", "circular-dep2", "circular-dep1", "test-with-circular-deps"]
    end
  end

  describe "loading LWRPs" do
    before do
      LibraryLoadOrder.reset!
    end

    # One big test for everything. Individual behaviors are tested by the attribute code above.
    it "loads LWRPs in run list order" do
      node.run_list("test-with-deps::default", "test-with-circular-deps::default")

      compiler.compile_lwrps
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
      node.run_list("test-with-deps::default", "test-with-circular-deps::default")

      compiler.compile_resource_definitions
      LibraryLoadOrder.load_order.should == ["dependency1-definition",
                                             "dependency2-definition",
                                             "test-with-deps-definition",
                                             "circular-dep2-definition",
                                             "circular-dep1-definition",
                                             "test-with-circular-deps-definition"]
    end

  end

  describe "loading recipes" do
    # Tests for this behavior are in RunContext's tests
  end

  describe "listing cookbook order" do 
    it "should return an array of cookbook names as symbols without duplicates" do
      node.run_list("test-with-circular-deps::default", "circular-dep1::default", "circular-dep2::default")

      compiler.cookbook_order.should == [:"circular-dep2",
                                         :"circular-dep1",
                                         :"test-with-circular-deps"]
    end
  end
end
