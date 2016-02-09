#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
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

require "chef/version_class"
require "chef/version_constraint"

describe Chef::RunList do
  before(:each) do
    @run_list = Chef::RunList.new
  end

  describe "<<" do
    it "should add a recipe to the run list and recipe list with the fully qualified name" do
      @run_list << "recipe[needy]"
      expect(@run_list).to include("recipe[needy]")
      expect(@run_list.recipes).to include("needy")
    end

    it "should add a role to the run list and role list with the fully qualified name" do
      @run_list << "role[woot]"
      expect(@run_list).to include("role[woot]")
      expect(@run_list.roles).to include("woot")
    end

    it "should accept recipes that are unqualified" do
      @run_list << "needy"
      expect(@run_list).to include("recipe[needy]")
      expect(@run_list.recipes.include?("needy")).to eq(true)
    end

    it "should not allow duplicates" do
      @run_list << "needy"
      @run_list << "needy"
      expect(@run_list.run_list.length).to eq(1)
      expect(@run_list.recipes.length).to eq(1)
    end

    it "should allow two versions of a recipe" do
      @run_list << "recipe[needy@0.2.0]"
      @run_list << "recipe[needy@0.1.0]"
      expect(@run_list.run_list.length).to eq(2)
      expect(@run_list.recipes.length).to eq(2)
      expect(@run_list.recipes.include?("needy")).to eq(true)
    end

    it "should not allow duplicate versions of a recipe" do
      @run_list << "recipe[needy@0.2.0]"
      @run_list << "recipe[needy@0.2.0]"
      expect(@run_list.run_list.length).to eq(1)
      expect(@run_list.recipes.length).to eq(1)
    end
  end

  describe "add" do
    # Testing only the basic functionality here
    # since full behavior is tested above.
    it "should add a recipe to the run_list" do
      @run_list.add "recipe[needy]"
      expect(@run_list).to include("recipe[needy]")
    end

    it "should add a role to the run_list" do
      @run_list.add "role[needy]"
      expect(@run_list).to include("role[needy]")
    end
  end

  describe "==" do
    it "should believe two RunLists are equal if they have the same members" do
      @run_list << "foo"
      r = Chef::RunList.new
      r << "foo"
      expect(@run_list).to eq(r)
    end

    it "should believe a RunList is equal to an array named after it's members" do
      @run_list << "foo"
      @run_list << "baz"
      expect(@run_list).to eq(%w{foo baz})
    end
  end

  describe "empty?" do
    it "should be emtpy if the run list has no members" do
      expect(@run_list.empty?).to eq(true)
    end

    it "should not be empty if the run list has members" do
      @run_list << "chromeo"
      expect(@run_list.empty?).to eq(false)
    end
  end

  describe "[]" do
    it "should let you look up a member in the run list by position" do
      @run_list << "recipe[loulou]"
      expect(@run_list[0]).to eq("recipe[loulou]")
    end
  end

  describe "[]=" do
    it "should let you set a member of the run list by position" do
      @run_list[0] = "recipe[loulou]"
      expect(@run_list[0]).to eq("recipe[loulou]")
    end

    it "should properly expand a member of the run list given by position" do
      @run_list[0] = "loulou"
      expect(@run_list[0]).to eq("recipe[loulou]")
    end
  end

  describe "each" do
    it "should yield each member to your block" do
      @run_list << "foo"
      @run_list << "bar"
      seen = Array.new
      @run_list.each { |r| seen << r }
      expect(seen).to be_include("recipe[foo]")
      expect(seen).to be_include("recipe[bar]")
    end
  end

  describe "each_index" do
    it "should yield each members index to your block" do
      to_add = [ "recipe[foo]", "recipe[bar]", "recipe[baz]" ]
      to_add.each { |i| @run_list << i }
      @run_list.each_index { |i| expect(@run_list[i]).to eq(to_add[i]) }
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
      list.each { |i| expect(@run_list).to be_include(i) }
      expect(@run_list.include?("chromeo")).to eq(false)
    end
  end

  describe "when expanding the run list" do
    before(:each) do
      @role = Chef::Role.new
      @role.name "stubby"
      @role.run_list "one", "two"
      @role.default_attributes :one => :two
      @role.override_attributes :three => :four
      @role.env_run_list["production"] = Chef::RunList.new( "one", "two", "five")

      allow(Chef::Role).to receive(:load).and_return(@role)
      @rest = double("Chef::ServerAPI", { :get => @role.to_hash, :url => "/" })
      allow(Chef::ServerAPI).to receive(:new).and_return(@rest)

      @run_list << "role[stubby]"
      @run_list << "kitty"
    end

    describe "from disk" do
      it "should load the role from disk" do
        expect(Chef::Role).to receive(:from_disk).with("stubby")
        @run_list.expand("_default", "disk")
      end

      it "should log a helpful error if the role is not available" do
        allow(Chef::Role).to receive(:from_disk).and_raise(Chef::Exceptions::RoleNotFound)
        expect(Chef::Log).to receive(:error).with("Role stubby (included by 'top level') is in the runlist but does not exist. Skipping expand.")
        @run_list.expand("_default", "disk")
      end
    end

    describe "from the chef server" do
      it "should load the role from the chef server" do
        #@rest.should_receive(:get).with("roles/stubby")
        expansion = @run_list.expand("_default", "server")
        expect(expansion.recipes).to eq(%w{one two kitty})
      end

      it "should default to expanding from the server" do
        expect(@rest).to receive(:get).with("roles/stubby")
        @run_list.expand("_default")
      end

      describe "with an environment set" do
        it "expands the run list using the environment specific run list" do
          expansion = @run_list.expand("production", "server")
          expect(expansion.recipes).to eq(%w{one two five kitty})
        end

        describe "and multiply nested roles" do
          before do
            @multiple_rest_requests = double("Chef::ServerAPI")

            @role.env_run_list["production"] << "role[prod-base]"

            @role_prod_base = Chef::Role.new
            @role_prod_base.name("prod-base")
            @role_prod_base.env_run_list["production"] = Chef::RunList.new("role[nested-deeper]")

            @role_nested_deeper = Chef::Role.new
            @role_nested_deeper.name("nested-deeper")
            @role_nested_deeper.env_run_list["production"] = Chef::RunList.new("recipe[prod-secret-sauce]")
          end

          it "expands the run list using the specified environment for all nested roles" do
            allow(Chef::ServerAPI).to receive(:new).and_return(@multiple_rest_requests)
            expect(@multiple_rest_requests).to receive(:get).with("roles/stubby").and_return(@role.to_hash)
            expect(@multiple_rest_requests).to receive(:get).with("roles/prod-base").and_return(@role_prod_base.to_hash)
            expect(@multiple_rest_requests).to receive(:get).with("roles/nested-deeper").and_return(@role_nested_deeper.to_hash)

            expansion = @run_list.expand("production", "server")
            expect(expansion.recipes).to eq(%w{one two five prod-secret-sauce kitty})
          end

        end

      end

    end

    it "should return the list of expanded recipes" do
      expansion = @run_list.expand("_default")
      expect(expansion.recipes[0]).to eq("one")
      expect(expansion.recipes[1]).to eq("two")
    end

    it "should return the list of default attributes" do
      expansion = @run_list.expand("_default")
      expect(expansion.default_attrs[:one]).to eq(:two)
    end

    it "should return the list of override attributes" do
      expansion = @run_list.expand("_default")
      expect(expansion.override_attrs[:three]).to eq(:four)
    end

    it "should recurse into a child role" do
      dog = Chef::Role.new
      dog.name "dog"
      dog.default_attributes :seven => :nine
      dog.run_list "three"
      @role.run_list << "role[dog]"
      allow(Chef::Role).to receive(:from_disk).with("stubby").and_return(@role)
      allow(Chef::Role).to receive(:from_disk).with("dog").and_return(dog)

      expansion = @run_list.expand("_default", "disk")
      expect(expansion.recipes[2]).to eq("three")
      expect(expansion.default_attrs[:seven]).to eq(:nine)
    end

    it "should not recurse infinitely" do
      dog = Chef::Role.new
      dog.name "dog"
      dog.default_attributes :seven => :nine
      dog.run_list "role[dog]", "three"
      @role.run_list << "role[dog]"
      allow(Chef::Role).to receive(:from_disk).with("stubby").and_return(@role)
      expect(Chef::Role).to receive(:from_disk).with("dog").once.and_return(dog)

      expansion = @run_list.expand("_default", "disk")
      expect(expansion.recipes[2]).to eq("three")
      expect(expansion.recipes[3]).to eq("kitty")
      expect(expansion.default_attrs[:seven]).to eq(:nine)
    end
  end

  describe "when converting to an alternate representation" do
    before do
      @run_list << "recipe[nagios::client]" << "role[production]" << "recipe[apache2]"
    end

    it "converts to an array of the string forms of its items" do
      expect(@run_list.to_a).to eq(["recipe[nagios::client]", "role[production]", "recipe[apache2]"])
    end

    it "converts to json by converting its array form" do
      expect(Chef::JSONCompat.to_json(@run_list)).to eq(Chef::JSONCompat.to_json(["recipe[nagios::client]", "role[production]", "recipe[apache2]"]))
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { @run_list }
    end

  end

end
