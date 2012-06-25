#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::RunList::RunListExpansion do
  before do
    @run_list = Chef::RunList.new
    @run_list << 'recipe[lobster]' << 'role[rage]' << 'recipe[fist]'
    @expansion = Chef::RunList::RunListExpansion.new("_default", @run_list.run_list_items)
  end

  describe "before expanding the run list" do
    it "has an array of run list items" do
      @expansion.run_list_items.should == @run_list.run_list_items
    end

    it "has default_attrs" do
      @expansion.default_attrs.should == Mash.new
    end

    it "has override attrs" do
      @expansion.override_attrs.should == Mash.new
    end

    it "it has an empty list of recipes" do
      @expansion.should have(0).recipes
    end

    it "has not applied its roles" do
      @expansion.applied_role?('rage').should be_false
    end
  end

  describe "after applying a role with environment-specific run lists" do
    before do
      @rage_role = Chef::Role.new.tap do |r|
        r.name("rage")
        r.env_run_lists('_default' => [], "prod" => ["recipe[prod-only]"])
      end
      @expansion = Chef::RunList::RunListExpansion.new("prod", @run_list.run_list_items)
      @expansion.should_receive(:fetch_role).and_return(@rage_role)
      @expansion.expand
    end

    it "has the correct list of recipes for the given environment" do
      @expansion.recipes.should == ["lobster", "prod-only", "fist"]
    end

  end

  describe "after applying a role" do
    before do
      @expansion.stub!(:fetch_role).and_return(Chef::Role.new)
      @expansion.inflate_role('rage', "role[base]")
    end

    it "tracks the applied role" do
      @expansion.applied_role?('rage').should be_true
    end

    it "does not inflate the role again" do
      @expansion.inflate_role('rage', "role[base]").should be_false
    end
  end

  describe "after expanding a run list" do
    before do
      @first_role = Chef::Role.new
      @first_role.run_list('role[mollusk]')
      @first_role.default_attributes({'foo' => 'bar'})
      @first_role.override_attributes({'baz' => 'qux'})
      @second_role = Chef::Role.new
      @second_role.run_list('recipe[crabrevenge]')
      @second_role.default_attributes({'foo' => 'boo'})
      @second_role.override_attributes({'baz' => 'bux'})
      @expansion.stub!(:fetch_role).and_return(@first_role, @second_role)
      @expansion.expand
    end

    it "has the ordered list of recipes" do
      @expansion.recipes.should == ['lobster', 'crabrevenge', 'fist']
    end

    it "has the merged attributes from the roles with outer roles overridding inner" do
      @expansion.default_attrs.should == {'foo' => 'bar'}
      @expansion.override_attrs.should == {'baz' => 'qux'}
    end

    it "has the list of all roles applied" do
      # this is the correct order, but 1.8 hash order is not stable
      @expansion.roles.should =~ ['rage', 'mollusk']
    end

  end

  describe "after expanding a run list with a non existant role" do
    before do
      @expansion.stub!(:fetch_role) { @expansion.role_not_found('crabrevenge', "role[base]") }
      @expansion.expand
    end

    it "is invalid" do
      @expansion.should be_invalid
      @expansion.errors?.should be_true # aliases
    end

    it "has a list of invalid role names" do
      @expansion.errors.should include('crabrevenge')
    end

  end

end
