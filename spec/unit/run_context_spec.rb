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
    @run_context.cookbook_collection.should == @cookbook_collection
  end

  it "has a node" do
    @run_context.node.should == @node
  end

  describe "loading cookbooks for a run list" do
    before do
      @node.run_list << "test" << "test::one" << "test::two"
      @node.should_receive(:loaded_recipe).with(:test, "default")
      @node.should_receive(:loaded_recipe).with(:test, "one")
      @node.should_receive(:loaded_recipe).with(:test, "two")
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

    it "raises an error when attempting to include_recipe from a cookbook not reachable by run list or dependencies" do
      @node.should_receive(:loaded_recipe).with(:ancient, "aliens")
      lambda do
        @run_context.include_recipe("ancient::aliens")
      # In CHEF-5120, this becomes a Chef::Exceptions::MissingCookbookDependency error:
      end.should raise_error(Chef::Exceptions::CookbookNotFound)
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
      @run_context.should have_template_in_cookbook("openldap", "test.erb")
      @run_context.should_not have_template_in_cookbook("openldap", "missing.erb")
    end

    it "errors when querying for a template in a not-available cookbook" do
      expect do
        @run_context.has_template_in_cookbook?("no-such-cookbook", "foo.erb")
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end

    it "queries whether a given cookbook has a specific cookbook_file" do
      @run_context.should have_cookbook_file_in_cookbook("java", "java.response")
      @run_context.should_not have_cookbook_file_in_cookbook("java", "missing.txt")
    end

    it "errors when querying for a cookbook_file in a not-available cookbook" do
      expect do
        @run_context.has_cookbook_file_in_cookbook?("no-such-cookbook", "foo.txt")
      end.to raise_error(Chef::Exceptions::CookbookNotFound)
    end
  end

end
