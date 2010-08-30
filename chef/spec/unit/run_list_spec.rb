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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::RunList do
  before(:each) do
    @run_list = Chef::RunList.new
  end

  describe "<<" do
    it "should add a recipe to the run list and recipe list with the fully qualified name" do
      @run_list << 'recipe[needy]'
      @run_list.should include('recipe[needy]')
      @run_list.recipes.should include("needy")
    end

    it "should add a role to the run list and role list with the fully qualified name" do
      @run_list << "role[woot]"
      @run_list.should include('role[woot]')
      @run_list.roles.should include('woot')
    end

    it "should accept recipes that are unqualified" do
      @run_list << "needy"
      @run_list.should include('recipe[needy]')
      #@run_list.include?('recipe[needy]').should == true
      @run_list.recipes.include?('needy').should == true
    end

    it "should not allow duplicates" do
      @run_list << "needy"
      @run_list << "needy"
      @run_list.run_list.length.should == 1
      @run_list.recipes.length.should == 1
    end

    it "should allow two versions of a recipe" do
      @run_list << "recipe[needy@0.2.0]"
      @run_list << "recipe[needy@0.1.0]"
      @run_list.run_list.length.should == 2
      @run_list.recipes.length.should == 2
      @run_list.recipes.include?('needy').should == true
    end
    

    it "should not allow duplicate versions of a recipe" do
      @run_list << "recipe[needy@0.2.0]"
      @run_list << "recipe[needy@0.2.0]"
      @run_list.run_list.length.should == 1
      @run_list.recipes.length.should == 1
    end
  end

  describe "==" do
    it "should believe two RunLists are equal if they have the same members" do
      @run_list << "foo"
      r = Chef::RunList.new
      r << "foo"
      @run_list.should == r
    end

    it "should believe a RunList is equal to an array named after it's members" do
      @run_list << "foo"
      @run_list << "baz"
      @run_list.should == [ "foo", "baz" ]
    end
  end

  describe "empty?" do
    it "should be emtpy if the run list has no members" do
      @run_list.empty?.should == true
    end

    it "should not be empty if the run list has members" do
      @run_list << "chromeo"
      @run_list.empty?.should == false
    end
  end

  describe "[]" do
    it "should let you look up a member in the run list by position" do
      @run_list << 'recipe[loulou]'
      @run_list[0].should == 'recipe[loulou]'
    end
  end

  describe "[]=" do
    it "should let you set a member of the run list by position" do
      @run_list[0] = 'recipe[loulou]'
      @run_list[0].should == 'recipe[loulou]'
    end

    it "should properly expand a member of the run list given by position" do
      @run_list[0] = 'loulou'
      @run_list[0].should == 'recipe[loulou]'
    end
  end

  describe "each" do
    it "should yield each member to your block" do
      @run_list << "foo"
      @run_list << "bar"
      seen = Array.new
      @run_list.each { |r| seen << r }
      seen.should be_include("recipe[foo]")
      seen.should be_include("recipe[bar]")
    end
  end

  describe "each_index" do
    it "should yield each members index to your block" do
      to_add = [ "recipe[foo]", "recipe[bar]", "recipe[baz]" ]
      to_add.each { |i| @run_list << i }
      @run_list.each_index { |i| @run_list[i].should == to_add[i] }
    end
  end

  describe "include?" do
    it "should be true if the run list includes the item" do
      @run_list << "foo"
      @run_list.include?("foo")
    end
  end

  describe "reset" do
    it "should reset the run_list based on the array you pass" do
      @run_list << "chromeo"
      list = %w{camp chairs snakes clowns}
      @run_list.reset!(list)
      list.each { |i| @run_list.should be_include(i) }
      @run_list.include?("chromeo").should == false
    end
  end

  describe "expand" do
    before(:each) do
      @role = Chef::Role.new
      @role.name "stubby"
      @role.run_list "one", "two"
      @role.default_attributes :one => :two
      @role.override_attributes :three => :four

      Chef::Role.stub!(:load).and_return(@role)
      @rest = mock("Chef::REST", { :get_rest => @role, :url => "/" })
      Chef::REST.stub!(:new).and_return(@rest)
      
      @run_list << "role[stubby]"
      @run_list << "kitty"
    end

    describe "from disk" do
      it "should load the role from disk" do
        Chef::Role.should_receive(:from_disk).with("stubby")
        @run_list.expand("disk")
      end

      it "should log a helpful error if the role is not available" do
        Chef::Role.stub!(:from_disk).and_raise(Chef::Exceptions::RoleNotFound)
        Chef::Log.should_receive(:error).with("Role stubby is in the runlist but does not exist. Skipping expand.")
        @run_list.expand("disk")
      end
    end

    describe "from the chef server" do
      it "should load the role from the chef server" do
        #@rest.should_receive(:get_rest).with("roles/stubby")
        expansion = @run_list.expand("server")
        expansion.recipes.should == ['one', 'two', 'kitty']
      end

      it "should default to expanding from the server" do
        @rest.should_receive(:get_rest).with("roles/stubby")
        @run_list.expand
      end
    end

    describe "from couchdb" do
      it "should load the role from couchdb" do
        Chef::Role.should_receive(:cdb_load).and_return(@role)
        @run_list.expand("couchdb")
      end
    end

    it "should return the list of expanded recipes" do
      expansion = @run_list.expand
      expansion.recipes[0].should == "one"
      expansion.recipes[1].should == "two"
    end

    it "should return the list of default attributes" do
      expansion = @run_list.expand
      expansion.default_attrs[:one].should == :two
    end

    it "should return the list of override attributes" do
      expansion = @run_list.expand
      expansion.override_attrs[:three].should == :four
    end

    it "should recurse into a child role" do
      dog = Chef::Role.new
      dog.name "dog"
      dog.default_attributes :seven => :nine
      dog.run_list "three"
      @role.run_list << "role[dog]"
      Chef::Role.stub!(:from_disk).with("stubby").and_return(@role)
      Chef::Role.stub!(:from_disk).with("dog").and_return(dog)

      expansion = @run_list.expand('disk')
      expansion.recipes[2].should == "three"
      expansion.default_attrs[:seven].should == :nine
    end

    it "should not recurse infinitely" do
      dog = Chef::Role.new
      dog.name "dog"
      dog.default_attributes :seven => :nine
      dog.run_list "role[dog]", "three"
      @role.run_list << "role[dog]"
      Chef::Role.stub!(:from_disk).with("stubby").and_return(@role)
      Chef::Role.should_receive(:from_disk).with("dog").once.and_return(dog)

      expansion = @run_list.expand('disk')
      expansion.recipes[2].should == "three"
      expansion.recipes[3].should == "kitty"
      expansion.default_attrs[:seven].should == :nine
    end

  end
end
