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

require 'spec_helper'
require 'ostruct'

describe Chef::Node do

  let(:node) { Chef::Node.new() }
  let(:platform_introspector) { node }

  it_behaves_like "a platform introspector"

  it "creates a node and assigns it a name" do
    node = Chef::Node.build('solo-node')
    expect(node.name).to eq('solo-node')
  end

  it "should validate the name of the node" do
    expect{Chef::Node.build('solo node')}.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "should be sortable" do
    n1 = Chef::Node.build('alpha')
    n2 = Chef::Node.build('beta')
    n3 = Chef::Node.build('omega')
    expect([n3, n1, n2].sort).to eq([n1, n2, n3])
  end

  describe "when the node does not exist on the server" do
    before do
      response = OpenStruct.new(:code => '404')
      exception = Net::HTTPServerException.new("404 not found", response)
      allow(Chef::Node).to receive(:load).and_raise(exception)
      node.name("created-node")
    end

    it "creates a new node for find_or_create" do
      allow(Chef::Node).to receive(:new).and_return(node)
      expect(node).to receive(:create).and_return(node)
      node = Chef::Node.find_or_create("created-node")
      expect(node.name).to eq('created-node')
      expect(node).to equal(node)
    end
  end

  describe "when the node exists on the server" do
    before do
      node.name('existing-node')
      allow(Chef::Node).to receive(:load).and_return(node)
    end

    it "loads the node via the REST API for find_or_create" do
      expect(Chef::Node.find_or_create('existing-node')).to equal(node)
    end
  end

  describe "run_state" do
    it "is an empty hash" do
      expect(node.run_state).to respond_to(:keys)
      expect(node.run_state).to be_empty
    end
  end

  describe "initialize" do
    it "should default to the '_default' chef_environment" do
      n = Chef::Node.new
      expect(n.chef_environment).to eq('_default')
    end
  end

  describe "name" do
    it "should allow you to set a name with name(something)" do
      expect { node.name("latte") }.not_to raise_error
    end

    it "should return the name with name()" do
      node.name("latte")
      expect(node.name).to eql("latte")
    end

    it "should always have a string for name" do
      expect { node.name(Hash.new) }.to raise_error(ArgumentError)
    end

    it "cannot be blank" do
      expect { node.name("")}.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "should not accept name doesn't match /^[\-[:alnum:]_:.]+$/" do
      expect { node.name("space in it")}.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "chef_environment" do
    it "should set an environment with chef_environment(something)" do
      expect { node.chef_environment("latte") }.not_to raise_error
    end

    it "should return the chef_environment with chef_environment()" do
      node.chef_environment("latte")
      expect(node.chef_environment).to eq("latte")
    end

    it "should disallow non-strings" do
      expect { node.chef_environment(Hash.new) }.to raise_error(ArgumentError)
      expect { node.chef_environment(42) }.to raise_error(ArgumentError)
    end

    it "cannot be blank" do
      expect { node.chef_environment("")}.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "attributes" do
    it "should have attributes" do
      expect(node.attribute).to be_a_kind_of(Hash)
    end

    it "should allow attributes to be accessed by name or symbol directly on node[]" do
      node.default["locust"] = "something"
      expect(node[:locust]).to eql("something")
      expect(node["locust"]).to eql("something")
    end

    it "should return nil if it cannot find an attribute with node[]" do
      expect(node["secret"]).to eql(nil)
    end

    it "does not allow you to set an attribute via node[]=" do
      expect  { node["secret"] = "shush" }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "should allow you to query whether an attribute exists with attribute?" do
      node.default["locust"] = "something"
      expect(node.attribute?("locust")).to eql(true)
      expect(node.attribute?("no dice")).to eql(false)
    end

    it "should let you go deep with attribute?" do
      node.set["battles"]["people"]["wonkey"] = true
      expect(node["battles"]["people"].attribute?("wonkey")).to eq(true)
      expect(node["battles"]["people"].attribute?("snozzberry")).to eq(false)
    end

    it "does not allow you to set an attribute via method_missing" do
      expect { node.sunshine = "is bright"}.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "should allow you get get an attribute via method_missing" do
      node.default.sunshine = "is bright"
      expect(node.sunshine).to eql("is bright")
    end

    describe "normal attributes" do
      it "should allow you to set an attribute with set, without pre-declaring a hash" do
        node.set[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set an attribute with set_unless" do
        node.set_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(false)
      end

      it "should not allow you to set an attribute with set_unless if it already exists" do
        node.set[:snoopy][:is_a_puppy] = true
        node.set_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set a value after a set_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.set_unless[:snoopy][:is_a_puppy] = false
        node.set[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should let you set a value after a 'dangling' set_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.set[:snoopy][:is_a_puppy] = "what"
        node.set_unless[:snoopy][:is_a_puppy]
        node.set[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "auto-vivifies attributes created via method syntax" do
        node.set.fuu.bahrr.baz = "qux"
        expect(node.fuu.bahrr.baz).to eq("qux")
      end

      it "should let you use tag as a convience method for the tags attribute" do
        node.normal['tags'] = ['one', 'two']
        node.tag('three', 'four')
        expect(node['tags']).to eq(['one', 'two', 'three', 'four'])
      end
    end

    describe "default attributes" do
      it "should be set with default, without pre-declaring a hash" do
        node.default[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set with default_unless without pre-declaring a hash" do
        node.default_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(false)
      end

      it "should not allow you to set an attribute with default_unless if it already exists" do
        node.default[:snoopy][:is_a_puppy] = true
        node.default_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set a value after a default_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.default_unless[:snoopy][:is_a_puppy] = false
        node.default[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set a value after a 'dangling' default_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.default[:snoopy][:is_a_puppy] = "what"
        node.default_unless[:snoopy][:is_a_puppy]
        node.default[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "auto-vivifies attributes created via method syntax" do
        node.default.fuu.bahrr.baz = "qux"
        expect(node.fuu.bahrr.baz).to eq("qux")
      end
    end

    describe "override attributes" do
      it "should be set with override, without pre-declaring a hash" do
        node.override[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set with override_unless without pre-declaring a hash" do
        node.override_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(false)
      end

      it "should not allow you to set an attribute with override_unless if it already exists" do
        node.override[:snoopy][:is_a_puppy] = true
        node.override_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set a value after an override_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.override_unless[:snoopy][:is_a_puppy] = false
        node.override[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set a value after a 'dangling' override_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.override_unless[:snoopy][:is_a_puppy] = "what"
        node.override_unless[:snoopy][:is_a_puppy]
        node.override[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "auto-vivifies attributes created via method syntax" do
        node.override.fuu.bahrr.baz = "qux"
        expect(node.fuu.bahrr.baz).to eq("qux")
      end
    end

    describe "globally deleting attributes" do
      context "with hash values" do
        before do
          node.role_default["mysql"]["server"]["port"] = 1234
          node.normal["mysql"]["server"]["port"] = 2345
          node.override["mysql"]["server"]["port"] = 3456
        end

        it "deletes all the values and returns the value with the highest precidence" do
          expect( node.rm("mysql", "server", "port") ).to eql(3456)
          expect( node["mysql"]["server"]["port"] ).to be_nil
          expect( node["mysql"]["server"] ).to eql({})
        end

        it "deletes nested things correctly" do
          node.default["mysql"]["client"]["client_setting"] = "foo"
          expect( node.rm("mysql", "server") ).to eql( {"port" => 3456} )
          expect( node["mysql"] ).to eql( { "client" => { "client_setting" => "foo" } } )
        end

        it "returns nil if the node attribute does not exist" do
          expect( node.rm("no", "such", "thing") ).to be_nil
        end

        it "can delete the entire tree" do
          expect( node.rm("mysql") ).to eql({"server"=>{"port"=>3456}})
        end
      end

      context "when trying to delete through a thing that isn't an array-like or hash-like object" do
        before do
          node.default["mysql"] = true
        end

        it "returns nil when you're two levels deeper" do
          expect( node.rm("mysql", "server", "port") ).to eql(nil)
        end

        it "returns nil when you're one level deeper" do
          expect( node.rm("mysql", "server") ).to eql(nil)
        end

        it "correctly deletes at the top level" do
          expect( node.rm("mysql") ).to eql(true)
        end
      end

      context "with array indexes" do
        before do
          node.role_default["mysql"]["server"][0]["port"] = 1234
          node.normal["mysql"]["server"][0]["port"] = 2345
          node.override["mysql"]["server"][0]["port"] = 3456
          node.override["mysql"]["server"][1]["port"] = 3456
        end

        it "deletes the array element" do
          expect( node.rm("mysql", "server", 0, "port") ).to eql(3456)
          expect( node["mysql"]["server"][0]["port"] ).to be_nil
          expect( node["mysql"]["server"][1]["port"] ).to eql(3456)
        end
      end

      context "with real arrays" do
        before do
          node.role_default["mysql"]["server"] = [ {
            "port" => 1234,
          } ]
          node.normal["mysql"]["server"] = [ {
            "port" => 2345,
          } ]
          node.override["mysql"]["server"] = [ {
            "port" => 3456,
          } ]
        end

        it "deletes the array element" do
          expect( node.rm("mysql", "server", 0, "port") ).to eql(3456)
          expect( node["mysql"]["server"][0]["port"] ).to be_nil
        end

        it "does not have a horrible error message when mistaking arrays for hashes" do
          expect { node.rm("mysql", "server", "port") }.to raise_error(TypeError, "Wrong type in index of attribute (did you use a Hash index on an Array?)")
        end
      end
    end

    describe "granular deleting attributes" do
      context "when only defaults exist" do
        before do
          node.role_default["mysql"]["server"]["port"] = 1234
          node.default["mysql"]["server"]["port"] = 2345
          node.force_default["mysql"]["server"]["port"] = 3456
        end

        it "returns the deleted values" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(3456)
        end

        it "returns nil for the combined attribues" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(3456)
          expect( node["mysql"]["server"]["port"] ).to eql(nil)
        end

        it "returns an empty hash for the default attrs" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(3456)
          # this auto-vivifies, should it?
          expect( node.default_attrs["mysql"]["server"]["port"] ).to eql({})
        end

        it "returns an empty hash after the last key is deleted" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(3456)
          expect( node["mysql"]["server"] ).to eql({})
        end
      end

      context "when trying to delete through a thing that isn't an array-like or hash-like object" do
        before do
          node.default["mysql"] = true
        end

        it "returns nil when you're two levels deeper" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(nil)
        end

        it "returns nil when you're one level deeper" do
          expect( node.rm_default("mysql", "server") ).to eql(nil)
        end

        it "correctly deletes at the top level" do
          expect( node.rm_default("mysql") ).to eql(true)
        end
      end

      context "when a higher precedence exists" do
        before do
          node.role_default["mysql"]["server"]["port"] = 1234
          node.default["mysql"]["server"]["port"] = 2345
          node.force_default["mysql"]["server"]["port"] = 3456

          node.override["mysql"]["server"]["port"] = 9999
        end

        it "returns the deleted values" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(3456)
        end

        it "returns the higher precedence values after the delete" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(3456)
          expect( node["mysql"]["server"]["port"] ).to eql(9999)
        end

        it "returns an empty has for the default attrs" do
          expect( node.rm_default("mysql", "server", "port") ).to eql(3456)
          # this auto-vivifies, should it?
          expect( node.default_attrs["mysql"]["server"]["port"] ).to eql({})
        end
      end

      context "when a lower precedence exists" do
        before do
          node.default["mysql"]["server"]["port"] = 2345
          node.override["mysql"]["server"]["port"] = 9999
          node.role_override["mysql"]["server"]["port"] = 9876
          node.force_override["mysql"]["server"]["port"] = 6669
        end

        it "returns the deleted values" do
          expect( node.rm_override("mysql", "server", "port") ).to eql(6669)
        end

        it "returns the lower precedence levels after the delete" do
          expect( node.rm_override("mysql", "server", "port") ).to eql(6669)
          expect( node["mysql"]["server"]["port"] ).to eql(2345)
        end

        it "returns an empty has for the override attrs" do
          expect( node.rm_override("mysql", "server", "port") ).to eql(6669)
          # this auto-vivifies, should it?
          expect( node.override_attrs["mysql"]["server"]["port"] ).to eql({})
        end
      end

      it "rm_default returns nil on deleting non-existent values" do
        expect( node.rm_default("no", "such", "thing") ).to be_nil
      end

      it "rm_normal returns nil on deleting non-existent values" do
        expect( node.rm_normal("no", "such", "thing") ).to be_nil
      end

      it "rm_override returns nil on deleting non-existent values" do
        expect( node.rm_override("no", "such", "thing") ).to be_nil
      end
    end

    describe "granular replacing attributes" do
      it "removes everything at the level of the last key" do
        node.default["mysql"]["server"]["port"] = 2345

        node.default!["mysql"]["server"] = { "data_dir" => "/my_raid_volume/lib/mysql" }

        expect( node["mysql"]["server"] ).to eql({ "data_dir" => "/my_raid_volume/lib/mysql" })
      end

      it "replaces a value at the cookbook sub-level of the atributes only" do
        node.default["mysql"]["server"]["port"] = 2345
        node.default["mysql"]["server"]["service_name"] = "fancypants-sql"
        node.role_default["mysql"]["server"]["port"] = 1234
        node.force_default["mysql"]["server"]["port"] = 3456

        node.default!["mysql"]["server"] = { "data_dir" => "/my_raid_volume/lib/mysql" }

        expect( node["mysql"]["server"]["port"] ).to eql(3456)
        expect( node["mysql"]["server"]["service_name"] ).to be_nil
        expect( node["mysql"]["server"]["data_dir"] ).to eql("/my_raid_volume/lib/mysql")
        expect( node["mysql"]["server"] ).to eql({ "port" => 3456, "data_dir" => "/my_raid_volume/lib/mysql" })
      end

      it "higher precedence values aren't removed" do
        node.role_default["mysql"]["server"]["port"] = 1234
        node.default["mysql"]["server"]["port"] = 2345
        node.force_default["mysql"]["server"]["port"] = 3456
        node.override["mysql"]["server"]["service_name"] = "fancypants-sql"

        node.default!["mysql"]["server"] = { "data_dir" => "/my_raid_volume/lib/mysql" }

        expect( node["mysql"]["server"]["port"] ).to eql(3456)
        expect( node["mysql"]["server"]["data_dir"] ).to eql("/my_raid_volume/lib/mysql")
        expect( node["mysql"]["server"] ).to eql({ "service_name" => "fancypants-sql", "port" => 3456, "data_dir" => "/my_raid_volume/lib/mysql" })
      end
    end

    describe "granular force replacing attributes" do
      it "removes everything at the level of the last key" do
        node.force_default["mysql"]["server"]["port"] = 2345

        node.force_default!["mysql"]["server"] = {
          "data_dir" => "/my_raid_volume/lib/mysql",
        }

        expect( node["mysql"]["server"] ).to eql({
          "data_dir" => "/my_raid_volume/lib/mysql",
        })
      end

      it "removes all values from the precedence level when setting" do
        node.role_default["mysql"]["server"]["port"] = 1234
        node.default["mysql"]["server"]["port"] = 2345
        node.force_default["mysql"]["server"]["port"] = 3456

        node.force_default!["mysql"]["server"] = {
          "data_dir" => "/my_raid_volume/lib/mysql",
        }

        expect( node["mysql"]["server"]["port"] ).to be_nil
        expect( node["mysql"]["server"]["data_dir"] ).to eql("/my_raid_volume/lib/mysql")
        expect( node["mysql"]["server"] ).to eql({
          "data_dir" => "/my_raid_volume/lib/mysql",
        })
      end

      it "higher precedence levels are not removed" do
        node.role_default["mysql"]["server"]["port"] = 1234
        node.default["mysql"]["server"]["port"] = 2345
        node.force_default["mysql"]["server"]["port"] = 3456
        node.override["mysql"]["server"]["service_name"] = "fancypants-sql"

        node.force_default!["mysql"]["server"] = {
          "data_dir" => "/my_raid_volume/lib/mysql",
        }

        expect( node["mysql"]["server"]["port"] ).to be_nil
        expect( node["mysql"]["server"]["data_dir"] ).to eql("/my_raid_volume/lib/mysql")
        expect( node["mysql"]["server"] ).to eql({
          "service_name" => "fancypants-sql",
          "data_dir" => "/my_raid_volume/lib/mysql",
        })
      end

      it "will autovivify" do
        node.force_default!["mysql"]["server"] = {
          "data_dir" => "/my_raid_volume/lib/mysql",
        }
        expect( node["mysql"]["server"]["data_dir"] ).to eql("/my_raid_volume/lib/mysql")
      end

      it "lower precedence levels aren't removed" do
        node.role_override["mysql"]["server"]["port"] = 1234
        node.override["mysql"]["server"]["port"] = 2345
        node.force_override["mysql"]["server"]["port"] = 3456
        node.default["mysql"]["server"]["service_name"] = "fancypants-sql"

        node.force_override!["mysql"]["server"] = {
          "data_dir" => "/my_raid_volume/lib/mysql",
        }

        expect( node["mysql"]["server"]["port"] ).to be_nil
        expect( node["mysql"]["server"]["data_dir"] ).to eql("/my_raid_volume/lib/mysql")
        expect( node["mysql"]["server"] ).to eql({
          "service_name" => "fancypants-sql",
          "data_dir" => "/my_raid_volume/lib/mysql",
        })
      end

      it "when overwriting a non-hash/array" do
        node.override["mysql"] = false
        node.force_override["mysql"] = true
        node.force_override!["mysql"]["server"] = {
          "data_dir" => "/my_raid_volume/lib/mysql",
        }
        expect( node["mysql"]["server"]["data_dir"] ).to eql("/my_raid_volume/lib/mysql")
      end

      it "when overwriting an array with a hash" do
        node.force_override["mysql"][0] = true
        node.force_override!["mysql"]["server"] = {
          "data_dir" => "/my_raid_volume/lib/mysql",
        }
        expect( node["mysql"]["server"] ).to eql({
          "data_dir" => "/my_raid_volume/lib/mysql",
        })
      end
    end

    # In Chef-12.0 there is a deep_merge cache on the top level attribute which had a bug
    # where it cached node[:foo] separate from node['foo'].  These tests exercise those edge conditions.
    #
    # https://github.com/opscode/chef/issues/2700
    # https://github.com/opscode/chef/issues/2712
    # https://github.com/opscode/chef/issues/2745
    #
    describe "deep merge attribute cache edge conditions" do
      it "does not error with complicated attribute substitution" do
        node.default['chef_attribute_hell']['attr1'] = "attribute1"
        node.default['chef_attribute_hell']['attr2'] = "#{node.chef_attribute_hell.attr1}/attr2"
        expect { node.default['chef_attribute_hell']['attr3'] = "#{node.chef_attribute_hell.attr2}/attr3" }.not_to raise_error
      end

      it "caches both strings and symbols correctly" do
        node.force_default[:solr][:version] = '4.10.2'
        node.force_default[:solr][:data_dir] = "/opt/solr-#{node['solr'][:version]}/example/solr"
        node.force_default[:solr][:xms] = "512M"
        expect(node[:solr][:xms]).to eql("512M")
        expect(node['solr'][:xms]).to eql("512M")
      end

      it "method interpolation syntax also works" do
        node.default['passenger']['version']     = '4.0.57'
        node.default['passenger']['root_path']   = "passenger-#{node['passenger']['version']}"
        node.default['passenger']['root_path_2'] = "passenger-#{node.passenger['version']}"
        expect(node['passenger']['root_path_2']).to eql("passenger-4.0.57")
        expect(node[:passenger]['root_path_2']).to eql("passenger-4.0.57")
      end
    end

    it "should raise an ArgumentError if you ask for an attribute that doesn't exist via method_missing" do
      expect { node.sunshine }.to raise_error(NoMethodError)
    end

    it "should allow you to iterate over attributes with each_attribute" do
      node.default.sunshine = "is bright"
      node.default.canada = "is a nice place"
      seen_attributes = Hash.new
      node.each_attribute do |a,v|
        seen_attributes[a] = v
      end
      expect(seen_attributes).to have_key("sunshine")
      expect(seen_attributes).to have_key("canada")
      expect(seen_attributes["sunshine"]).to eq("is bright")
      expect(seen_attributes["canada"]).to eq("is a nice place")
    end
  end

  describe "consuming json" do

    before do
      @ohai_data = {:platform => 'foo', :platform_version => 'bar'}
    end

    it "consumes the run list portion of a collection of attributes and returns the remainder" do
      attrs = {"run_list" => [ "role[base]", "recipe[chef::server]" ], "foo" => "bar"}
      expect(node.consume_run_list(attrs)).to eq({"foo" => "bar"})
      expect(node.run_list).to eq([ "role[base]", "recipe[chef::server]" ])
    end

    it "should overwrites the run list with the run list it consumes" do
      node.consume_run_list "recipes" => [ "one", "two" ]
      node.consume_run_list "recipes" => [ "three" ]
      expect(node.run_list).to eq([ "three" ])
    end

    it "should not add duplicate recipes from the json attributes" do
      node.run_list << "one"
      node.consume_run_list "recipes" => [ "one", "two", "three" ]
      expect(node.run_list).to  eq([ "one", "two", "three" ])
    end

    it "doesn't change the run list if no run_list is specified in the json" do
      node.run_list << "role[database]"
      node.consume_run_list "foo" => "bar"
      expect(node.run_list).to eq(["role[database]"])
    end

    it "raises an exception if you provide both recipe and run_list attributes, since this is ambiguous" do
      expect { node.consume_run_list "recipes" => "stuff", "run_list" => "other_stuff" }.to raise_error(Chef::Exceptions::AmbiguousRunlistSpecification)
    end

    it "should add json attributes to the node" do
      node.consume_external_attrs(@ohai_data, {"one" => "two", "three" => "four"})
      expect(node.one).to eql("two")
      expect(node.three).to eql("four")
    end

    it "should set the tags attribute to an empty array if it is not already defined" do
      node.consume_external_attrs(@ohai_data, {})
      expect(node.tags).to eql([])
    end

    it "should not set the tags attribute to an empty array if it is already defined" do
      node.normal[:tags] = [ "radiohead" ]
      node.consume_external_attrs(@ohai_data, {})
      expect(node.tags).to eql([ "radiohead" ])
    end

    it "deep merges attributes instead of overwriting them" do
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "four"}})
      expect(node.one.to_hash).to eq({"two" => {"three" => "four"}})
      node.consume_external_attrs(@ohai_data, "one" => {"abc" => "123"})
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"foo" => "bar"}})
      expect(node.one.to_hash).to eq({"two" => {"three" => "four", "foo" => "bar"}, "abc" => "123"})
    end

    it "gives attributes from JSON priority when deep merging" do
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "four"}})
      expect(node.one.to_hash).to eq({"two" => {"three" => "four"}})
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "forty-two"}})
      expect(node.one.to_hash).to eq({"two" => {"three" => "forty-two"}})
    end

  end

  describe "preparing for a chef client run" do
    before do
      @ohai_data = {:platform => 'foobuntu', :platform_version => '23.42'}
    end

    it "sets its platform according to platform detection" do
      node.consume_external_attrs(@ohai_data, {})
      expect(node.automatic_attrs[:platform]).to eq('foobuntu')
      expect(node.automatic_attrs[:platform_version]).to eq('23.42')
    end

    it "consumes the run list from provided json attributes" do
      node.consume_external_attrs(@ohai_data, {"run_list" => ['recipe[unicorn]']})
      expect(node.run_list).to eq(['recipe[unicorn]'])
    end

    it "saves non-runlist json attrs for later" do
      expansion = Chef::RunList::RunListExpansion.new('_default', [])
      allow(node.run_list).to receive(:expand).and_return(expansion)
      node.consume_external_attrs(@ohai_data, {"foo" => "bar"})
      node.expand!
      expect(node.normal_attrs).to eq({"foo" => "bar", "tags" => []})
    end

  end

  describe "when expanding its run list and merging attributes" do
    before do
      @environment = Chef::Environment.new.tap do |e|
        e.name('rspec_env')
        e.default_attributes("env default key" => "env default value")
        e.override_attributes("env override key" => "env override value")
      end
      expect(Chef::Environment).to receive(:load).with("rspec_env").and_return(@environment)
      @expansion = Chef::RunList::RunListExpansion.new("rspec_env", [])
      node.chef_environment("rspec_env")
      allow(node.run_list).to receive(:expand).and_return(@expansion)
    end

    it "sets the 'recipes' automatic attribute to the recipes in the expanded run_list" do
      @expansion.recipes << 'recipe[chef::client]' << 'recipe[nginx::default]'
      node.expand!
      expect(node.automatic_attrs[:recipes]).to eq(['recipe[chef::client]', 'recipe[nginx::default]'])
    end

    it "sets the 'roles' automatic attribute to the expanded role list" do
      @expansion.instance_variable_set(:@applied_roles, {'arf' => nil, 'countersnark' => nil})
      node.expand!
      expect(node.automatic_attrs[:roles].sort).to eq(['arf', 'countersnark'])
    end

    it "applies default attributes from the environment as environment defaults" do
      node.expand!
      expect(node.attributes.env_default["env default key"]).to eq("env default value")
    end

    it "applies override attributes from the environment as env overrides" do
      node.expand!
      expect(node.attributes.env_override["env override key"]).to eq("env override value")
    end

    it "applies default attributes from roles as role defaults" do
      @expansion.default_attrs["role default key"] = "role default value"
      node.expand!
      expect(node.attributes.role_default["role default key"]).to eq("role default value")
    end

    it "applies override attributes from roles as role overrides" do
      @expansion.override_attrs["role override key"] = "role override value"
      node.expand!
      expect(node.attributes.role_override["role override key"]).to eq("role override value")
    end
  end

  describe "loaded_recipe" do
    it "should not add a recipe that is already in the recipes list" do
      node.automatic_attrs[:recipes] = [ "nginx::module" ]
      node.loaded_recipe(:nginx, "module")
      expect(node.automatic_attrs[:recipes].length).to eq(1)
    end

    it "should add a recipe that is not already in the recipes list" do
      node.automatic_attrs[:recipes] = [ "nginx::other_module" ]
      node.loaded_recipe(:nginx, "module")
      expect(node.automatic_attrs[:recipes].length).to eq(2)
      expect(node.recipe?("nginx::module")).to be true
      expect(node.recipe?("nginx::other_module")).to be true
    end
  end

  describe "when querying for recipes in the run list" do
    context "when a recipe is in the top level run list" do
      before do
        node.run_list << "recipe[nginx::module]"
      end

      it "finds the recipe" do
        expect(node.recipe?("nginx::module")).to be true
      end

      it "does not find a recipe not in the run list" do
        expect(node.recipe?("nginx::other_module")).to be false
      end
    end
    context "when a recipe is in the expanded run list only" do
      before do
        node.run_list << "role[base]"
        node.automatic_attrs[:recipes] = [ "nginx::module" ]
      end

      it "finds a recipe in the expanded run list" do
        expect(node.recipe?("nginx::module")).to be true
      end

      it "does not find a recipe that's not in the run list" do
        expect(node.recipe?("nginx::other_module")).to be false
      end
    end
  end

  describe "when clearing computed state at the beginning of a run" do
    before do
      node.default[:foo] = "default"
      node.normal[:foo] = "normal"
      node.override[:foo] = "override"
      node.reset_defaults_and_overrides
    end

    it "removes default attributes" do
      expect(node.default).to be_empty
    end

    it "removes override attributes" do
      expect(node.override).to be_empty
    end

    it "leaves normal level attributes untouched" do
      expect(node[:foo]).to eq("normal")
    end

  end

  describe "when merging environment attributes" do
    before do
      node.chef_environment = "rspec"
      @expansion = Chef::RunList::RunListExpansion.new("rspec", [])
      @expansion.default_attrs.replace({:default => "from role", :d_role => "role only"})
      @expansion.override_attrs.replace({:override => "from role", :o_role => "role only"})

      @environment = Chef::Environment.new
      @environment.default_attributes = {:default => "from env", :d_env => "env only" }
      @environment.override_attributes = {:override => "from env", :o_env => "env only"}
      allow(Chef::Environment).to receive(:load).and_return(@environment)
      node.apply_expansion_attributes(@expansion)
    end

    it "does not nuke role-only default attrs" do
      expect(node[:d_role]).to eq("role only")
    end

    it "does not nuke role-only override attrs" do
      expect(node[:o_role]).to eq("role only")
    end

    it "does not nuke env-only default attrs" do
      expect(node[:o_env]).to eq("env only")
    end

    it "does not nuke role-only override attrs" do
      expect(node[:o_env]).to eq("env only")
    end

    it "gives role defaults precedence over env defaults" do
      expect(node[:default]).to eq("from role")
    end

    it "gives env overrides precedence over role overrides" do
      expect(node[:override]).to eq("from env")
    end
  end

  describe "when evaluating attributes files" do
    before do
      @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
      @cookbook_loader = Chef::CookbookLoader.new(@cookbook_repo)
      @cookbook_loader.load_cookbooks

      @cookbook_collection = Chef::CookbookCollection.new(@cookbook_loader.cookbooks_by_name)

      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(node, @cookbook_collection, @events)

      node.include_attribute("openldap::default")
      node.include_attribute("openldap::smokey")
    end

    it "sets attributes from the files" do
      expect(node.ldap_server).to eql("ops1prod")
      expect(node.ldap_basedn).to eql("dc=hjksolutions,dc=com")
      expect(node.ldap_replication_password).to eql("forsure")
      expect(node.smokey).to eql("robinson")
    end

    it "gives a sensible error when attempting to load a missing attributes file" do
      expect { node.include_attribute("nope-this::doesnt-exist") }.to raise_error(Chef::Exceptions::CookbookNotFound)
    end
  end

  describe "roles" do
    it "should allow you to query whether or not it has a recipe applied with role?" do
      node.run_list << "role[sunrise]"
      expect(node.role?("sunrise")).to eql(true)
      expect(node.role?("not at home")).to eql(false)
    end

    it "should allow you to set roles with arguments" do
      node.run_list << "role[one]"
      node.run_list << "role[two]"
      expect(node.role?("one")).to eql(true)
      expect(node.role?("two")).to eql(true)
    end
  end

  describe "run_list" do
    it "should have a Chef::RunList of recipes and roles that should be applied" do
      expect(node.run_list).to be_a_kind_of(Chef::RunList)
    end

    it "should allow you to query the run list with arguments" do
      node.run_list "recipe[baz]"
      expect(node.run_list?("recipe[baz]")).to eql(true)
    end

    it "should allow you to set the run list with arguments" do
      node.run_list "recipe[baz]", "role[foo]"
      expect(node.run_list?("recipe[baz]")).to eql(true)
      expect(node.run_list?("role[foo]")).to eql(true)
    end
  end

  describe "from file" do
    it "should load a node from a ruby file" do
      node.from_file(File.expand_path(File.join(CHEF_SPEC_DATA, "nodes", "test.rb")))
      expect(node.name).to eql("test.example.com-short")
      expect(node.sunshine).to eql("in")
      expect(node.something).to eql("else")
      expect(node.run_list).to eq(["operations-master", "operations-monitoring"])
    end

    it "should raise an exception if the file cannot be found or read" do
      expect { node.from_file("/tmp/monkeydiving") }.to raise_error(IOError)
    end
  end

  describe "update_from!" do
    before(:each) do
      node.name("orig")
      node.chef_environment("dev")
      node.default_attrs = { "one" => { "two" => "three", "four" => "five", "eight" => "nine" } }
      node.override_attrs = { "one" => { "two" => "three", "four" => "six" } }
      node.normal_attrs = { "one" => { "two" => "seven" } }
      node.run_list << "role[marxist]"
      node.run_list << "role[leninist]"
      node.run_list << "recipe[stalinist]"

      @example = Chef::Node.new()
      @example.name("newname")
      @example.chef_environment("prod")
      @example.default_attrs = { "alpha" => { "bravo" => "charlie", "delta" => "echo" } }
      @example.override_attrs = { "alpha" => { "bravo" => "foxtrot", "delta" => "golf" } }
      @example.normal_attrs = { "alpha" => { "bravo" => "hotel" } }
      @example.run_list << "role[comedy]"
      @example.run_list << "role[drama]"
      @example.run_list << "recipe[mystery]"
    end

    it "allows update of everything except name" do
      node.update_from!(@example)
      expect(node.name).to eq("orig")
      expect(node.chef_environment).to eq(@example.chef_environment)
      expect(node.default_attrs).to eq(@example.default_attrs)
      expect(node.override_attrs).to eq(@example.override_attrs)
      expect(node.normal_attrs).to eq(@example.normal_attrs)
      expect(node.run_list).to eq(@example.run_list)
    end

    it "should not update the name of the node" do
      expect(node).not_to receive(:name).with(@example.name)
      node.update_from!(@example)
    end
  end

  describe "to_hash" do
    it "should serialize itself as a hash" do
      node.chef_environment("dev")
      node.default_attrs = { "one" => { "two" => "three", "four" => "five", "eight" => "nine" } }
      node.override_attrs = { "one" => { "two" => "three", "four" => "six" } }
      node.normal_attrs = { "one" => { "two" => "seven" } }
      node.run_list << "role[marxist]"
      node.run_list << "role[leninist]"
      node.run_list << "recipe[stalinist]"
      h = node.to_hash
      expect(h["one"]["two"]).to eq("three")
      expect(h["one"]["four"]).to eq("six")
      expect(h["one"]["eight"]).to eq("nine")
      expect(h["role"]).to be_include("marxist")
      expect(h["role"]).to be_include("leninist")
      expect(h["run_list"]).to be_include("role[marxist]")
      expect(h["run_list"]).to be_include("role[leninist]")
      expect(h["run_list"]).to be_include("recipe[stalinist]")
      expect(h["chef_environment"]).to eq("dev")
    end

    it 'should return an empty array for empty run_list' do
      expect(node.to_hash["run_list"]).to eq([])
    end
  end

  describe "converting to or from json" do
    it "should serialize itself as json", :json => true do
      node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
      json = Chef::JSONCompat.to_json(node)
      expect(json).to match(/json_class/)
      expect(json).to match(/name/)
      expect(json).to match(/chef_environment/)
      expect(json).to match(/normal/)
      expect(json).to match(/default/)
      expect(json).to match(/override/)
      expect(json).to match(/run_list/)
    end

    it 'should serialize valid json with a run list', :json => true do
      #This test came about because activesupport mucks with Chef json serialization
      #Test should pass with and without Activesupport
      node.run_list << {"type" => "role", "name" => 'Cthulu'}
      node.run_list << {"type" => "role", "name" => 'Hastur'}
      json = Chef::JSONCompat.to_json(node)
      expect(json).to match(/\"run_list\":\[\"role\[Cthulu\]\",\"role\[Hastur\]\"\]/)
    end

    it "should serialize the correct run list", :json => true do
      node.run_list << "role[marxist]"
      node.run_list << "role[leninist]"
      node.override_runlist << "role[stalinist]"
      expect(node.run_list).to be_include("role[stalinist]")
      json = Chef::JSONCompat.to_json(node)
      expect(json).to match(/\"run_list\":\[\"role\[marxist\]\",\"role\[leninist\]\"\]/)
    end

    it "merges the override components into a combined override object" do
      node.attributes.role_override["role override"] = "role override"
      node.attributes.env_override["env override"] = "env override"
      node_for_json = node.for_json
      expect(node_for_json["override"]["role override"]).to eq("role override")
      expect(node_for_json["override"]["env override"]).to eq("env override")
    end

    it "merges the default components into a combined default object" do
      node.attributes.role_default["role default"] = "role default"
      node.attributes.env_default["env default"] = "env default"
      node_for_json = node.for_json
      expect(node_for_json["default"]["role default"]).to eq("role default")
      expect(node_for_json["default"]["env default"]).to eq("env default")
    end

    it "should deserialize itself from json", :json => true do
      node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
      json = Chef::JSONCompat.to_json(node)
      serialized_node = Chef::JSONCompat.from_json(json)
      expect(serialized_node).to be_a_kind_of(Chef::Node)
      expect(serialized_node.name).to eql(node.name)
      expect(serialized_node.chef_environment).to eql(node.chef_environment)
      node.each_attribute do |k,v|
        expect(serialized_node[k]).to eql(v)
      end
      expect(serialized_node.run_list).to eq(node.run_list)
    end

    include_examples "to_json equalivent to Chef::JSONCompat.to_json" do
      let(:jsonable) {
        node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
        node
      }
    end
  end

  describe "to_s" do
    it "should turn into a string like node[name]" do
      node.name("airplane")
      expect(node.to_s).to eql("node[airplane]")
    end
  end

  describe "api model" do
    before(:each) do
      @rest = double("Chef::REST")
      allow(Chef::REST).to receive(:new).and_return(@rest)
      @query = double("Chef::Search::Query")
      allow(Chef::Search::Query).to receive(:new).and_return(@query)
    end

    describe "list" do
      describe "inflated" do
        it "should return a hash of node names and objects" do
          n1 = double("Chef::Node", :name => "one")
          expect(@query).to receive(:search).with(:node).and_yield(n1)
          r = Chef::Node.list(true)
          expect(r["one"]).to eq(n1)
        end
      end

      it "should return a hash of node names and urls" do
        expect(@rest).to receive(:get_rest).and_return({ "one" => "http://foo" })
        r = Chef::Node.list
        expect(r["one"]).to eq("http://foo")
      end
    end

    describe "load" do
      it "should load a node by name" do
        expect(@rest).to receive(:get_rest).with("nodes/monkey").and_return("foo")
        expect(Chef::Node.load("monkey")).to eq("foo")
      end
    end

    describe "destroy" do
      it "should destroy a node" do
        expect(@rest).to receive(:delete_rest).with("nodes/monkey").and_return("foo")
        node.name("monkey")
        node.destroy
      end
    end

    describe "save" do
      it "should update a node if it already exists" do
        node.name("monkey")
        allow(node).to receive(:data_for_save).and_return({})
        expect(@rest).to receive(:put_rest).with("nodes/monkey", {}).and_return("foo")
        node.save
      end

      it "should not try and create if it can update" do
        node.name("monkey")
        allow(node).to receive(:data_for_save).and_return({})
        expect(@rest).to receive(:put_rest).with("nodes/monkey", {}).and_return("foo")
        expect(@rest).not_to receive(:post_rest)
        node.save
      end

      it "should create if it cannot update" do
        node.name("monkey")
        allow(node).to receive(:data_for_save).and_return({})
        exception = double("404 error", :code => "404")
        expect(@rest).to receive(:put_rest).and_raise(Net::HTTPServerException.new("foo", exception))
        expect(@rest).to receive(:post_rest).with("nodes", {})
        node.save
      end

      describe "when whyrun mode is enabled" do
        before do
          Chef::Config[:why_run] = true
        end
        after do
          Chef::Config[:why_run] = false
        end
        it "should not save" do
          node.name("monkey")
          expect(@rest).not_to receive(:put_rest)
          expect(@rest).not_to receive(:post_rest)
          node.save
        end
      end

      context "with whitelisted attributes configured" do
        it "should only save whitelisted attributes (and subattributes)" do
          Chef::Config[:automatic_attribute_whitelist] = [
            ["filesystem", "/dev/disk0s2"],
            "network/interfaces/eth0"
          ]

          data = {
            "automatic" => {
              "filesystem" => {
                "/dev/disk0s2"   => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" }
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {},
                  "eth1" => {}
                }
              }
            },
            "default" => {}, "normal" => {}, "override" => {}
          }

          selected_data = {
            "automatic" => {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" }
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {}
                }
              }
            },
            "default" => {}, "normal" => {}, "override" => {}
          }

          node.name("picky-monkey")
          allow(node).to receive(:for_json).and_return(data)
          expect(@rest).to receive(:put_rest).with("nodes/picky-monkey", selected_data).and_return("foo")
          node.save
        end

        it "should save false-y whitelisted attributes" do
          Chef::Config[:default_attribute_whitelist] = [
            "foo/bar/baz"
          ]

          data = {
            "default" => {
              "foo" => {
                "bar" => {
                  "baz" => false,
                },
                "other" => {
                  "stuff" => true,
                }
              }
            }
          }

          selected_data = {
            "default" => {
              "foo" => {
                "bar" => {
                  "baz" => false,
                }
              }
            }
          }

          node.name("falsey-monkey")
          allow(node).to receive(:for_json).and_return(data)
          expect(@rest).to receive(:put_rest).with("nodes/falsey-monkey", selected_data).and_return("foo")
          node.save
        end

        it "should not save any attributes if the whitelist is empty" do
          Chef::Config[:automatic_attribute_whitelist] = []

          data = {
            "automatic" => {
              "filesystem" => {
                "/dev/disk0s2"   => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" }
              }
            },
            "default" => {}, "normal" => {}, "override" => {}
          }

          selected_data = {
            "automatic" => {}, "default" => {}, "normal" => {}, "override" => {}
          }

          node.name("picky-monkey")
          allow(node).to receive(:for_json).and_return(data)
          expect(@rest).to receive(:put_rest).with("nodes/picky-monkey", selected_data).and_return("foo")
          node.save
        end
      end
    end
  end

end
