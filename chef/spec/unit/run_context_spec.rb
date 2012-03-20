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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

Chef::Log.level = :debug

describe Chef::RunContext do
  before(:each) do
    Chef::Config.node_path(File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "nodes")))
    @chef_repo_path = File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "cookbooks"))
    @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new(@chef_repo_path))
    @node = Chef::Node.new
    @node.find_file("run_context")
    @run_context = Chef::RunContext.new(@node, @cookbook_collection)
  end

  it "has a cookbook collection" do
    @run_context.cookbook_collection.should == @cookbook_collection
  end

  it "has a node" do
    @run_context.node.should == @node
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
  end

  describe "after loading the cookbooks" do
    before do
      @run_context = nil
    end

    describe "after setting allowed recipes to 'partials'" do
      before do
        Chef::Config[:allowed_recipes] = 'partials'
        @run_context = Chef::RunContext.new(@node, @cookbook_collection)
        @run_context.load(@node.run_list.expand('_default'))
      end

      after do
        Chef::Config[:allowed_recipes] = nil
      end

      it "should only show 'partials' from the run list in the runnable recipes list" do
        @run_context.node.run_state[:runnable_recipes].should include('partials')
        @run_context.node.run_list.run_list_items.each do |item|
          next if %w(partials partials::default).include?(item.name)
          @run_context.node.run_state[:runnable_recipes].should_not include(item.name)
        end
      end

      it "should show 'partials::default' dependency in the runnable recipes list" do
        @run_context.node.run_state[:runnable_recipes].should include('partials::breaker')
      end
    end

    describe "after setting the restricted recipes to 'partials'" do
      before do
        Chef::Config[:restricted_recipes] = 'partials'
        @run_context = Chef::RunContext.new(@node, @cookbook_collection)
        @run_context.load(@node.run_list.expand('_default'))
      end

      after do
        Chef::Config[:restricted_recipes] = nil
      end

      it "should show all recipes from the run list except 'partials'" do
        @run_context.node.run_state[:runnable_recipes].should_not include('partials')
        @run_context.node.run_list.run_list_items.each do |item|
          next if %w(partials partials::default).include?(item.name)
          @run_context.node.run_state[:runnable_recipes].should include(item.name)
        end
      end
    end

    describe "after setting the restricted recipes to 'partials::breaker'" do
      before do
        Chef::Config[:restricted_recipes] = 'partials::breaker'
        @run_context = Chef::RunContext.new(@node, @cookbook_collection)
        @run_context.load(@node.run_list.expand('_default'))
      end

      after do
        Chef::Config[:restricted_recipes] = nil
      end

      it "should not show 'partials' in runnable recipes due to dependency on 'partials::breaker'" do
        @run_context.node.run_state[:runnable_recipes].should_not include('partials')
        @run_context.node.run_list.run_list_items.each do |item|
          next if %w(partials partials::default).include?(item.name)
          @run_context.node.run_state[:runnable_recipes].should include(item.name)
        end
      end
    end

    describe "after setting the allowed recipes to test and partials and restricted recipes to 'partials'" do
      before do
        Chef::Config[:restricted_recipes] = 'partials'
        Chef::Config[:allowed_recipes] = 'test,partials'
        @run_context = Chef::RunContext.new(@node, @cookbook_collection)
        @run_context.load(@node.run_list.expand('_default'))
      end

      after do
        Chef::Config[:restricted_recipes] = nil
        Chef::Config[:allowed_recipes] = nil
      end

      it "should only show 'test' in runnable recipes" do
        @run_context.node.run_state[:runnable_recipes].should eql ['test']
      end
    end
  end

end
