#
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::ResourceCollection do
  let(:run_context) do
    cookbook_repo = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "data", "cookbooks"))
    cookbook_loader = Chef::CookbookLoader.new(cookbook_repo)
    cookbook_loader.load_cookbooks
    node = Chef::Node.new
    cookbook_collection = Chef::CookbookCollection.new(cookbook_loader)
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, cookbook_collection, events)
  end

  let(:recipe) do
    Chef::Recipe.new("hjk", "test", run_context)
  end

  describe "#declare_resource" do
    before do
      recipe.declare_resource(:zen_master, "monkey") do
        something true
      end
    end

    it "inserts into the resource collection" do
      expect(run_context.resource_collection.first.to_s).to eql("zen_master[monkey]")
    end

    it "sets the property from the block" do
      expect(run_context.resource_collection.first.something).to be true
    end
  end

  describe "#edit_resource!" do
    it "raises if nothing is found" do
      expect do
        recipe.edit_resource!(:zen_master, "monkey") do
          something true
        end
      end.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "raises if nothing is found and no block is given" do
      expect do
        recipe.edit_resource!(:zen_master, "monkey")
      end.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "edits the resource if it finds one" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.edit_resource!(:zen_master, "monkey") do
          something true
        end
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first.something).to be true
    end

    it "acts like find_resource! if not given a block and the resource exists" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.edit_resource!(:zen_master, "monkey")
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first.something).to be false
    end
  end

  describe "#edit_resource" do
    it "inserts a resource if nothing is found" do
      resource = recipe.edit_resource(:zen_master, "monkey") do
        something true
      end
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first).to eql(resource)
      expect(run_context.resource_collection.first.something).to be true
    end

    it "inserts a resource even if not given a block" do
      resource = recipe.edit_resource(:zen_master, "monkey")
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first).to eql(resource)
    end

    it "edits the resource if it finds one" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.edit_resource(:zen_master, "monkey") do
          something true
        end
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first.something).to be true
    end

    it "acts like find_resource if not given a block and the resource exists" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.edit_resource(:zen_master, "monkey")
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first.something).to be false
    end
  end

  describe "#find_resource!" do
    it "raises if nothing is found" do
      expect do
        recipe.find_resource!(:zen_master, "monkey")
      end.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "raises if given a block" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect do
        recipe.find_resource!(:zen_master, "monkey") do
          something false
        end
      end.to raise_error(ArgumentError)
    end

    it "returns the resource if it finds one" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.find_resource!(:zen_master, "monkey")
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first.something).to be false
    end
  end

  describe "#find_resource without block" do
    it "returns nil if nothing is found" do
      expect(recipe.find_resource(:zen_master, "monkey")).to be nil
      expect(run_context.resource_collection.all_resources.size).to eql(0)
    end

    it "returns the resource if it finds one" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.find_resource(:zen_master, "monkey")
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first.something).to be false
    end
  end

  describe "#find_resource with block" do
    it "inserts a resource if nothing is found" do
      resource = recipe.find_resource(:zen_master, "monkey") do
        something true
      end
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first).to eql(resource)
      expect(run_context.resource_collection.first.something).to be true
    end

    it "returns the resource if it finds one" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.find_resource(:zen_master, "monkey") do
          something true
        end
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(run_context.resource_collection.first.something).to be false
    end
  end

  describe "#delete_resource" do
    it "returns nil if nothing is found" do
      expect(
        recipe.delete_resource(:zen_master, "monkey")
      ).to be nil
    end

    it "deletes and returns the resource if it finds one" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.delete_resource(:zen_master, "monkey")
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(0)
    end
  end

  describe "#delete_resource!" do
    it "raises if nothing is found" do
      expect do
        recipe.delete_resource!(:zen_master, "monkey")
      end.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "deletes and returns the resource if it finds one" do
      resource = recipe.declare_resource(:zen_master, "monkey") do
        something false
      end
      expect(
        recipe.delete_resource!(:zen_master, "monkey")
      ).to eql(resource)
      expect(run_context.resource_collection.all_resources.size).to eql(0)
    end

    it "removes pending delayed notifications" do
      recipe.declare_resource(:zen_master, "one")
      recipe.declare_resource(:zen_master, "two") do
        notifies :win, "zen_master[one]"
      end
      recipe.delete_resource(:zen_master, "two")
      resource = recipe.declare_resource(:zen_master, "two")
      expect(resource.delayed_notifications).to eql([])
    end

    it "removes pending immediate notifications" do
      recipe.declare_resource(:zen_master, "one")
      recipe.declare_resource(:zen_master, "two") do
        notifies :win, "zen_master[one]", :immediate
      end
      recipe.delete_resource(:zen_master, "two")
      resource = recipe.declare_resource(:zen_master, "two")
      expect(resource.immediate_notifications).to eql([])
    end

    it "removes pending before notifications" do
      recipe.declare_resource(:zen_master, "one")
      recipe.declare_resource(:zen_master, "two") do
        notifies :win, "zen_master[one]", :before
      end
      recipe.delete_resource(:zen_master, "two")
      resource = recipe.declare_resource(:zen_master, "two")
      expect(resource.before_notifications).to eql([])
    end
  end

  describe "run_context helpers" do

    let(:parent_run_context) do
      run_context.create_child
    end

    let(:child_run_context) do
      parent_run_context.create_child
    end

    let(:parent_recipe) do
      Chef::Recipe.new("hjk", "parent", parent_run_context)
    end

    let(:child_recipe) do
      Chef::Recipe.new("hjk", "child", child_run_context)
    end

    before do
      # wire up our outer run context to the root Chef.run_context
      allow(Chef).to receive(:run_context).and_return(run_context)
    end

    it "our tests have correct separation" do
      child_resource = child_recipe.declare_resource(:zen_master, "child") do
        something false
      end
      parent_resource = parent_recipe.declare_resource(:zen_master, "parent") do
        something false
      end
      root_resource = recipe.declare_resource(:zen_master, "root") do
        something false
      end
      expect(run_context.resource_collection.first).to eql(root_resource)
      expect(run_context.resource_collection.first.to_s).to eql("zen_master[root]")
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(parent_run_context.resource_collection.first).to eql(parent_resource)
      expect(parent_run_context.resource_collection.first.to_s).to eql("zen_master[parent]")
      expect(parent_run_context.resource_collection.all_resources.size).to eql(1)
      expect(child_run_context.resource_collection.first).to eql(child_resource)
      expect(child_run_context.resource_collection.first.to_s).to eql("zen_master[child]")
      expect(child_run_context.resource_collection.all_resources.size).to eql(1)
    end

    it "with_run_context with :parent lets us build resources in the parent run_context from the child" do
      child_recipe.instance_eval do
        with_run_context(:parent) do
          declare_resource(:zen_master, "parent") do
            something false
          end
        end
      end
      expect(run_context.resource_collection.all_resources.size).to eql(0)
      expect(parent_run_context.resource_collection.all_resources.size).to eql(1)
      expect(parent_run_context.resource_collection.first.to_s).to eql("zen_master[parent]")
      expect(child_run_context.resource_collection.all_resources.size).to eql(0)
    end

    it "with_run_context with :root lets us build resources in the root run_context from the child" do
      child_recipe.instance_eval do
        with_run_context(:root) do
          declare_resource(:zen_master, "root") do
            something false
          end
        end
      end
      expect(run_context.resource_collection.first.to_s).to eql("zen_master[root]")
      expect(run_context.resource_collection.all_resources.size).to eql(1)
      expect(parent_run_context.resource_collection.all_resources.size).to eql(0)
      expect(child_run_context.resource_collection.all_resources.size).to eql(0)
    end

    it "with_run_context also takes a RunContext object as an argument" do
      child_recipe.instance_exec(parent_run_context) do |parent_run_context|
        with_run_context(parent_run_context) do
          declare_resource(:zen_master, "parent") do
            something false
          end
        end
      end
      expect(run_context.resource_collection.all_resources.size).to eql(0)
      expect(parent_run_context.resource_collection.all_resources.size).to eql(1)
      expect(parent_run_context.resource_collection.first.to_s).to eql("zen_master[parent]")
      expect(child_run_context.resource_collection.all_resources.size).to eql(0)
    end

    it "with_run_context returns the return value of the block" do
      child_recipe.instance_eval do
        ret = with_run_context(:root) do
          "return value"
        end
        raise "failed" unless ret == "return value"
      end
    end
  end
end
