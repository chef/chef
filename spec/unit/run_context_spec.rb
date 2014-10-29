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
require 'support/lib/library_load_order'

Chef::Log.level = :debug

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
    expect(@run_context.cookbook_collection).to eq(@cookbook_collection)
  end

  it "has a node" do
    expect(@run_context.node).to eq(@node)
  end

  describe "loading cookbooks for a run list" do
    before do

      # Each invocation reloads LWRPs, which triggers constant redefinition
      # warnings. In real usage this isn't an issue because of fork mode.
      if Chef::Provider.const_defined?(:TestProvider)
        Chef::Provider.send(:remove_const, :TestProvider)
      end

      @node.run_list << "test" << "test::one" << "test::two"
      expect(@node).to receive(:loaded_recipe).with(:test, "default")
      expect(@node).to receive(:loaded_recipe).with(:test, "one")
      expect(@node).to receive(:loaded_recipe).with(:test, "two")
      @run_context.load(@node.run_list.expand('_default'))
    end

    it "should load all the definitions in the cookbooks for this node" do
      expect(@run_context.definitions).to have_key(:new_cat)
      expect(@run_context.definitions).to have_key(:new_badger)
      expect(@run_context.definitions).to have_key(:new_dog)
    end

    it "should load all the recipes specified for this node" do
      expect(@run_context.resource_collection[0].to_s).to eq("cat[einstein]")
      expect(@run_context.resource_collection[1].to_s).to eq("cat[loulou]")
      expect(@run_context.resource_collection[2].to_s).to eq("cat[birthday]")
      expect(@run_context.resource_collection[3].to_s).to eq("cat[peanut]")
      expect(@run_context.resource_collection[4].to_s).to eq("cat[fat peanut]")
    end

    it "loads all the attribute files in the cookbook collection" do
      expect(@run_context.loaded_fully_qualified_attribute?("test", "george")).to be_truthy
      expect(@node[:george]).to eq("washington")
    end

    it "registers attributes files as loaded so they won't be reloaded" do
      # This test unfortunately is pretty tightly intertwined with the
      # implementation of how nodes load attribute files, but is the only
      # convenient way to test this behavior.
      expect(@node).not_to receive(:from_file)
      @node.include_attribute("test::george")
    end

    it "raises an error when attempting to include_recipe from a cookbook not reachable by run list or dependencies" do
      expect(@node).to receive(:loaded_recipe).with(:ancient, "aliens")
      expect do
        @run_context.include_recipe("ancient::aliens")
      # In CHEF-5120, this becomes a Chef::Exceptions::MissingCookbookDependency error:
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end

  end

  describe "querying the contents of cookbooks" do
    before do
      @chef_repo_path = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
      cl = Chef::CookbookLoader.new(@chef_repo_path)
      cl.load_cookbooks
      @cookbook_collection = Chef::CookbookCollection.new(cl)
      @node = Chef::Node.new
      @node.set[:platform] = "ubuntu"
      @node.set[:platform_version] = "13.04"
      @node.name("testing")
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    end


    it "queries whether a given cookbook has a specific template" do
      expect(@run_context).to have_template_in_cookbook("openldap", "test.erb")
      expect(@run_context).not_to have_template_in_cookbook("openldap", "missing.erb")
    end

    it "errors when querying for a template in a not-available cookbook" do
      expect do
        @run_context.has_template_in_cookbook?("no-such-cookbook", "foo.erb")
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end

    it "queries whether a given cookbook has a specific cookbook_file" do
      expect(@run_context).to have_cookbook_file_in_cookbook("java", "java.response")
      expect(@run_context).not_to have_cookbook_file_in_cookbook("java", "missing.txt")
    end

    it "errors when querying for a cookbook_file in a not-available cookbook" do
      expect do
        @run_context.has_cookbook_file_in_cookbook?("no-such-cookbook", "foo.txt")
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end
  end

  describe "handling reboot requests" do
    let(:expected) do
      { :reason => "spec tests require a reboot" }
    end

    it "stores and deletes the reboot request" do
      @run_context.request_reboot(expected)
      expect(@run_context.reboot_info).to eq(expected)
      expect(@run_context.reboot_requested?).to be_truthy

      @run_context.cancel_reboot
      expect(@run_context.reboot_info).to eq({})
      expect(@run_context.reboot_requested?).to be_falsey
    end
  end
end
