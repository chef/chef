#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "spec_helper"
require "support/lib/library_load_order"

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
  let(:run_list_expansion) { node.run_list.expand("_default") }

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
      expect(node[:attr_load_order]).to eq(["dependency1::default", "dependency1::aa_first", "dependency1::zz_last"])
    end

    it "loads dependencies before loading the depending cookbook's attributes" do
      # Also make sure that attributes aren't loaded twice if we have two
      # recipes from the same cookbook in the run list
      node.run_list("test-with-deps::default", "test-with-deps::server")

      compiler.compile_attributes

      # dependencies are stored in a hash so therefore unordered, but they should be loaded in sort order
      expect(node[:attr_load_order]).to eq(["dependency1::default",
                                        "dependency1::aa_first",
                                        "dependency1::zz_last",
                                        "dependency2::default",
                                        "test-with-deps::default"])
    end

    it "does not follow infinite dependency loops" do
      node.run_list("test-with-circular-deps::default")

      # Circular deps should not cause infinite loops
      compiler.compile_attributes

      expect(node[:attr_load_order]).to eq(["circular-dep2::default", "circular-dep1::default", "test-with-circular-deps::default"])
    end

    it "loads attributes from cookbooks that don't have a default.rb attribute file" do
      node.run_list("no-default-attr::default.rb")

      compiler.compile_attributes

      expect(node[:attr_load_order]).to eq(["no-default-attr::server"])
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
      expect(LibraryLoadOrder.load_order).to eq(["dependency1", "dependency2", "test-with-deps", "circular-dep2", "circular-dep1", "test-with-circular-deps"])
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
      expect(LibraryLoadOrder.load_order).to eq(["dependency1-provider",
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
                                             "test-with-circular-deps-resource"])
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
      expect(LibraryLoadOrder.load_order).to eq(["dependency1-definition",
                                             "dependency2-definition",
                                             "test-with-deps-definition",
                                             "circular-dep2-definition",
                                             "circular-dep1-definition",
                                             "test-with-circular-deps-definition"])
    end

  end

  describe "loading recipes" do
    # Additional tests for this behavior are in RunContext's tests

    describe "event dispatch" do
      let(:recipe) { "dependency1::default" }
      let(:recipe_path) do
        File.expand_path("../../../data/run_context/cookbooks/dependency1/recipes/default.rb", __FILE__)
      end
      before do
        node.run_list(recipe)
      end
      subject { compiler.compile_recipes }

      it "dispatches normally" do
        allow(run_context).to receive(:load_recipe)
        expect(events).to receive(:recipe_load_start).with(1)
        expect(events).to receive(:recipe_file_loaded).with(recipe_path, "dependency1::default")
        expect(events).to receive(:recipe_load_complete).with(no_args)
        subject
      end

      it "dispatches when a recipe is not found" do
        exc = Chef::Exceptions::RecipeNotFound.new
        allow(run_context).to receive(:load_recipe).and_raise(exc)
        expect(events).to receive(:recipe_load_start).with(1)
        expect(events).to_not receive(:recipe_file_loaded)
        expect(events).to receive(:recipe_not_found).with(exc)
        expect(events).to_not receive(:recipe_load_complete)
        expect { subject }.to raise_error(exc)
      end

      it "dispatches when a recipe has an error" do
        exc = ArgumentError.new
        allow(run_context).to receive(:load_recipe).and_raise(exc)
        expect(events).to receive(:recipe_load_start).with(1)
        expect(events).to_not receive(:recipe_file_loaded)
        expect(events).to receive(:recipe_file_load_failed).with(recipe_path, exc, "dependency1::default")
        expect(events).to_not receive(:recipe_load_complete)
        expect { subject }.to raise_error(exc)
      end
    end

  end

  describe "listing cookbook order" do
    it "should return an array of cookbook names as symbols without duplicates" do
      node.run_list("test-with-circular-deps::default", "circular-dep1::default", "circular-dep2::default")

      expect(compiler.cookbook_order).to eq([:"circular-dep2",
                                         :"circular-dep1",
                                         :"test-with-circular-deps"])
    end

    it "determines if a cookbook is in the list of cookbooks reachable by dependency" do
      node.run_list("test-with-deps::default", "test-with-deps::server")
      expect(compiler.cookbook_order).to eq([:dependency1, :dependency2, :"test-with-deps"])
      expect(compiler.unreachable_cookbook?(:dependency1)).to be_falsey
      expect(compiler.unreachable_cookbook?(:dependency2)).to be_falsey
      expect(compiler.unreachable_cookbook?(:'test-with-deps')).to be_falsey
      expect(compiler.unreachable_cookbook?(:'circular-dep1')).to be_truthy
      expect(compiler.unreachable_cookbook?(:'circular-dep2')).to be_truthy
    end

  end
end
