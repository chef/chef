#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
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
require "support/lib/library_load_order"

describe Chef::RunContext do
  let(:chef_repo_path) { File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "cookbooks")) }
  let(:cookbook_collection) do
    cl = Chef::CookbookLoader.new(chef_repo_path)
    cl.load_cookbooks
    Chef::CookbookCollection.new(cl)
  end
  let(:node) do
    node = Chef::Node.new
    node.run_list << "test" << "test::one" << "test::two"
    node
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }

  before(:each) do
    @original_log_level = Chef::Log.level
    Chef::Log.level = :debug
  end

  after(:each) do
    Chef::Log.level = @original_log_level
  end

  it "has a cookbook collection" do
    expect(run_context.cookbook_collection).to eq(cookbook_collection)
  end

  it "has a node" do
    expect(run_context.node).to eq(node)
  end

  it "loads up node[:cookbooks]" do
    expect(run_context.node[:cookbooks]).to eql(
      {
        "circular-dep1" => {
          "version" => "0.0.0",
        },
        "circular-dep2" => {
          "version" => "0.0.0",
        },
        "dependency1" => {
          "version" => "0.0.0",
        },
        "dependency2" => {
          "version" => "0.0.0",
        },
        "include" => {
          "version" => "0.0.0",
        },
        "no-default-attr" => {
          "version" => "0.0.0",
        },
        "test" => {
          "version" => "0.0.0",
        },
        "test-with-circular-deps" => {
          "version" => "0.0.0",
        },
        "test-with-deps" => {
          "version" => "0.0.0",
        },
      }
    )
  end

  it "has a nil parent_run_context" do
    expect(run_context.parent_run_context).to be_nil
  end

  describe "loading cookbooks for a run list" do
    before do

      # Each invocation reloads LWRPs, which triggers constant redefinition
      # warnings. In real usage this isn't an issue because of fork mode.
      if Chef::Provider.const_defined?(:TestProvider)
        Chef::Provider.send(:remove_const, :TestProvider)
      end

      node.run_list << "test" << "test::one" << "test::two"
      expect(node).to receive(:loaded_recipe).with(:test, "default")
      expect(node).to receive(:loaded_recipe).with(:test, "one")
      expect(node).to receive(:loaded_recipe).with(:test, "two")
      run_context.load(node.run_list.expand("_default"))
    end

    it "should load all the definitions in the cookbooks for this node" do
      expect(run_context.definitions).to have_key(:new_cat)
      expect(run_context.definitions).to have_key(:new_badger)
      expect(run_context.definitions).to have_key(:new_dog)
    end

    it "should load all the recipes specified for this node" do
      expect(run_context.resource_collection[0].to_s).to eq("cat[einstein]")
      expect(run_context.resource_collection[1].to_s).to eq("cat[loulou]")
      expect(run_context.resource_collection[2].to_s).to eq("cat[birthday]")
      expect(run_context.resource_collection[3].to_s).to eq("cat[peanut]")
      expect(run_context.resource_collection[4].to_s).to eq("cat[fat peanut]")
    end

    it "loads all the attribute files in the cookbook collection" do
      expect(run_context.loaded_fully_qualified_attribute?("test", "george")).to be_truthy
      expect(node[:george]).to eq("washington")
    end

    it "registers attributes files as loaded so they won't be reloaded" do
      # This test unfortunately is pretty tightly intertwined with the
      # implementation of how nodes load attribute files, but is the only
      # convenient way to test this behavior.
      expect(node).not_to receive(:from_file)
      node.include_attribute("test::george")
    end

    it "raises an error when attempting to include_recipe from a cookbook not reachable by run list or dependencies" do
      expect(node).to receive(:loaded_recipe).with(:ancient, "aliens")
      expect do
        run_context.include_recipe("ancient::aliens")
      # In CHEF-5120, this becomes a Chef::Exceptions::MissingCookbookDependency error:
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end

    it "raises an error on a recipe with a leading :: with no current_cookbook" do
      expect do
        run_context.include_recipe("::aliens")
      end.to raise_error(RuntimeError)
    end
  end

  describe "querying the contents of cookbooks" do
    let(:chef_repo_path) { File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks")) }
    let(:node) do
      node = Chef::Node.new
      node.normal[:platform] = "ubuntu"
      node.normal[:platform_version] = "13.04"
      node.name("testing")
      node
    end

    it "queries whether a given cookbook has a specific template" do
      expect(run_context).to have_template_in_cookbook("openldap", "test.erb")
      expect(run_context).not_to have_template_in_cookbook("openldap", "missing.erb")
    end

    it "errors when querying for a template in a not-available cookbook" do
      expect do
        run_context.has_template_in_cookbook?("no-such-cookbook", "foo.erb")
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end

    it "queries whether a given cookbook has a specific cookbook_file" do
      expect(run_context).to have_cookbook_file_in_cookbook("java", "java.response")
      expect(run_context).not_to have_cookbook_file_in_cookbook("java", "missing.txt")
    end

    it "errors when querying for a cookbook_file in a not-available cookbook" do
      expect do
        run_context.has_cookbook_file_in_cookbook?("no-such-cookbook", "foo.txt")
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end
  end

  describe "handling reboot requests" do
    let(:expected) do
      { :reason => "spec tests require a reboot" }
    end

    it "stores and deletes the reboot request" do
      run_context.request_reboot(expected)
      expect(run_context.reboot_info).to eq(expected)
      expect(run_context.reboot_requested?).to be_truthy

      run_context.cancel_reboot
      expect(run_context.reboot_info).to eq({})
      expect(run_context.reboot_requested?).to be_falsey
    end
  end

  describe "notifications" do
    let(:notification) { Chef::Resource::Notification.new(nil, nil, notifying_resource) }

    shared_context "notifying resource is a Chef::Resource" do
      let(:notifying_resource) { Chef::Resource.new("gerbil") }

      it "should be keyed off the resource name" do
        run_context.send(setter, notification)
        expect(run_context.send(getter, notifying_resource)).to eq([notification])
      end
    end

    shared_context "notifying resource is a subclass of Chef::Resource" do
      let(:declared_type) { :alpaca }
      let(:notifying_resource) do
        r = Class.new(Chef::Resource).new("guinea pig")
        r.declared_type = declared_type
        r
      end

      it "should be keyed off the resource declared key" do
        run_context.send(setter, notification)
        expect(run_context.send(getter, notifying_resource)).to eq([notification])
      end
    end

    describe "of the immediate kind" do
      let(:setter) { :notifies_immediately }
      let(:getter) { :immediate_notifications }
      include_context "notifying resource is a Chef::Resource"
      include_context "notifying resource is a subclass of Chef::Resource"
    end

    describe "of the delayed kind" do
      let(:setter) { :notifies_delayed }
      let(:getter) { :delayed_notifications }
      include_context "notifying resource is a Chef::Resource"
      include_context "notifying resource is a subclass of Chef::Resource"
    end
  end
end
