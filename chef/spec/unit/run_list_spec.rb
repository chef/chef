#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

require 'dep_selector/version'
require 'dep_selector/version_constraint'

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

  describe "when expanding the run list" do
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

      describe "with an environment set" do
        before do
          @role.env_run_list["production"] = Chef::RunList.new( "one", "two", "five")
        end

        it "expands the run list using the environment specific run list" do
          expansion = @run_list.expand("server", :environment => "production")
          expansion.recipes.should == %w{one two five kitty}
        end

        describe "and multiply nested roles" do
          before do
            @multiple_rest_requests = mock("Chef::REST")

            @role.env_run_list["production"] << "role[prod-base]"

            @role_prod_base = Chef::Role.new
            @role_prod_base.name("prod-base")
            @role_prod_base.env_run_list["production"] = Chef::RunList.new("role[nested-deeper]")


            @role_nested_deeper = Chef::Role.new
            @role_nested_deeper.name("nested-deeper")
            @role_nested_deeper.env_run_list["production"] = Chef::RunList.new("recipe[prod-secret-sauce]")
          end

          it "expands the run list using the specified environment for all nested roles" do
            Chef::REST.stub!(:new).and_return(@multiple_rest_requests)
            @multiple_rest_requests.should_receive(:get_rest).with("roles/stubby").and_return(@role)
            @multiple_rest_requests.should_receive(:get_rest).with("roles/prod-base").and_return(@role_prod_base)
            @multiple_rest_requests.should_receive(:get_rest).with("roles/nested-deeper").and_return(@role_nested_deeper)

            expansion = @run_list.expand("server", :environment => "production")
            expansion.recipes.should == %w{one two five prod-secret-sauce kitty}
          end

        end

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

  describe "when converting to an alternate representation" do
    before do
      @run_list << "recipe[nagios::client]" << "role[production]" << "recipe[apache2]"
    end

    it "converts to an array of the string forms of its items" do
      @run_list.to_a.should == ["recipe[nagios::client]", "role[production]", "recipe[apache2]"]
    end

    it "converts to json by converting its array form" do
      @run_list.to_json.should == ["recipe[nagios::client]", "role[production]", "recipe[apache2]"].to_json
    end

  end

  describe "constrain" do
    @fake_db = Object.new

    def cookbook_maker(name, version, deps)
      book = Chef::CookbookVersion.new(name, @fake_db)
      book.version = version
      deps.each { |dep_name, vc| book.metadata.depends(dep_name, vc) }
      book
    end
 
    def vc_maker(cookbook_name, version_constraint)
      vc = DepSelector::VersionConstraint.new(version_constraint)
      { :name => cookbook_name, :version_constraint => vc }
    end

    def assert_failure(run_list, all_cookbooks, constraints, exception_class, expected_message)
      begin
        run_list.constrain(all_cookbooks, constraints)
        fail "Should have raised a Chef::Exceptions::CookbookVersionConflict exception"
      rescue exception_class => cvc
        cvc.message.should include(expected_message)
      end
    end

    before(:each) do
      a = cookbook_maker("a", "1.0", [["c", "< 4.0"]])
      b = cookbook_maker("b", "1.0", [["c", "< 3.0"]])
      
      c2 = cookbook_maker("c", "2.0", [["d", "> 1.0"], ["f", nil]])
      c3 = cookbook_maker("c", "3.0", [["d", "> 2.0"], ["e", nil]])

      d1 = cookbook_maker("d", "1.1", [])
      d2 = cookbook_maker("d", "2.1", [])
      e = cookbook_maker("e", "1.0", [])
      f = cookbook_maker("f", "1.0", [])
      g = cookbook_maker("g", "1.0", [["d", "> 5.0"]])

      n1_1 = cookbook_maker("n", "1.1", [])
      n1_2 = cookbook_maker("n", "1.2", [])
      n1_10 = cookbook_maker("n", "1.10", [])

      @all_cookbooks = {
        "a" => [a],
        "b" => [b],
        "c" => [c2, c3],
        "d" => [d1, d2],
        "e" => [e],
        "f" => [f],
        "g" => [g],
        "n" => [n1_1, n1_2, n1_10]
      }
    end

    it "pulls in transitive dependencies" do
      constraints = [vc_maker("a", "~> 1.0")]
      cookbooks = @run_list.constrain(@all_cookbooks, constraints)
      %w(a c d e).each { |k| cookbooks.should have_key k }
      cookbooks.size.should == 4
      cookbooks["c"].version.should == "3.0.0"
      cookbooks["d"].version.should == "2.1.0"
    end

    it "properly sorts version triples, treating each term numerically" do
      constraints = [vc_maker("n", "> 1.2")]
      cookbooks = @run_list.constrain(@all_cookbooks, constraints)
      cookbooks.size.should == 1
      cookbooks["n"].version.should == "1.10.0"
    end

    it "should fail to find a solution when a run list item is constrained to a range that includes no cookbooks" do
      constraints = [vc_maker("d", "> 5.0")]
      assert_failure(@run_list, @all_cookbooks, constraints, Chef::Exceptions::CookbookVersionConflict, "unsatisfiability introduced at solution constraint (d > 5.0.0)")
    end

    it "should fail to find a solution when a run list item's dependency is constrained to a range that includes no cookbooks" do
      constraints = [vc_maker("g", nil)]
      assert_failure(@run_list, @all_cookbooks, constraints, Chef::Exceptions::CookbookVersionConflict, "unsatisfiability introduced at solution constraint (g >= 0.0.0)")
    end

    it "selects 'd 2.1.0' given constraint 'd > 1.2.3'" do
      constraints = [vc_maker("d", "> 1.2.3")]
      cookbooks = @run_list.constrain(@all_cookbooks, constraints)
      cookbooks.size.should == 1
      cookbooks["d"].version.should == "2.1.0"
    end

    it "selects largest version when constraint allows multiple" do
      constraints = [vc_maker("d", "> 1.0")]
      cookbooks = @run_list.constrain(@all_cookbooks, constraints)
      cookbooks.size.should == 1
      cookbooks["d"].version.should == "2.1.0"
    end

    it "selects 'd 1.1.0' given constraint 'd ~> 1.0'" do
      constraints = [vc_maker("d", "~> 1.0")]
      cookbooks = @run_list.constrain(@all_cookbooks, constraints)
      cookbooks.size.should == 1
      cookbooks["d"].version.should == "1.1.0"
    end

    it "raises CookbookVersionUnavailable for an unknown cookbook in the run list" do
      constraints = [vc_maker("nosuch", "1.0.0")]
      assert_failure(@run_list, @all_cookbooks, constraints, Chef::Exceptions::CookbookVersionUnavailable, "Cookbook nosuch does not exist")
    end

    it "raises CookbookVersionUnavailable for an unknown cookbook in a cookbook's depencies" do
      depends_on_nosuch = cookbook_maker("depends_on_nosuch", "1.0", [["nosuch", nil]])
      cbs = @all_cookbooks.merge({"depends_on_nosuch" => [depends_on_nosuch]})
      constraints = [vc_maker("depends_on_nosuch", "1.0.0")]
      assert_failure(@run_list, cbs, constraints, Chef::Exceptions::CookbookVersionUnavailable, "Cookbook depends_on_nosuch version 1.0.0 lists a dependency on cookbook nosuch, which does not exist")
    end

    it "raises CookbookVersionConflict for direct conflict" do
      constraints = [vc_maker("d", "= 1.1.0"), vc_maker("d", ">= 2.0")]
      assert_failure(@run_list, @all_cookbooks, constraints, Chef::Exceptions::CookbookVersionConflict, "unsatisfiability introduced at solution constraint (d >= 2.0.0)")
    end

    describe "should solve regardless of constraint order" do

      it "raises CookbookVersionConflict a then b" do
        # Cookbooks a and b both have a dependency on c, but with
        # differing constraints.
        constraints = [vc_maker("a", "1.0"), vc_maker("b", "1.0")]
        cookbooks = @run_list.constrain(@all_cookbooks, constraints)
        cookbooks.size.should == 5
        %w(a b c d f).each { |k| cookbooks.should have_key k }
        cookbooks["a"].version.should == "1.0.0"
        cookbooks["b"].version.should == "1.0.0"
        cookbooks["c"].version.should == "2.0.0"
        cookbooks["d"].version.should == "2.1.0"
      end

      it "resolves b then a" do
        # See above comment for a then b.  When b is pulled in first,
        # we should get a version of c that satifies the constraints
        # on the c dependency for both b and a.
        constraints = [vc_maker("b", "1.0"), vc_maker("a", "1.0")]
        cookbooks = @run_list.constrain(@all_cookbooks, constraints)
        cookbooks.size.should == 5
        %w(a b c d f).each { |k| cookbooks.should have_key k }
        cookbooks["a"].version.should == "1.0.0"
        cookbooks["b"].version.should == "1.0.0"
        cookbooks["c"].version.should == "2.0.0"
        cookbooks["d"].version.should == "2.1.0"
      end

      it "resolves a then d" do
        constraints = [vc_maker("a", "1.0"), vc_maker("d", "1.1")]
        cookbooks = @run_list.constrain(@all_cookbooks, constraints)
        cookbooks.size.should == 4
        %w(a c d f).each { |k| cookbooks.should have_key k }
        cookbooks["a"].version.should == "1.0.0"
        cookbooks["c"].version.should == "2.0.0"
        cookbooks["d"].version.should == "1.1.0"
      end

      it "resolves d then a" do
        constraints = [vc_maker("d", "1.1"), vc_maker("a", "1.0")]
        cookbooks = @run_list.constrain(@all_cookbooks, constraints)
        cookbooks.size.should == 4
        %w(a c d f).each { |k| cookbooks.should have_key k }
        cookbooks["a"].version.should == "1.0.0"
        cookbooks["c"].version.should == "2.0.0"
        cookbooks["d"].version.should == "1.1.0"
      end

    end
  end
end
