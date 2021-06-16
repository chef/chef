#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "ostruct"

describe Chef::Node do

  let(:node) { Chef::Node.new }
  let(:platform_introspector) { node }

  it_behaves_like "a platform introspector"

  it "creates a node and assigns it a name" do
    node = Chef::Node.build("solo-node")
    expect(node.name).to eq("solo-node")
  end

  it "should validate the name of the node" do
    expect { Chef::Node.build("solo node") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "should be sortable" do
    n1 = Chef::Node.build("alpha")
    n2 = Chef::Node.build("beta")
    n3 = Chef::Node.build("omega")
    expect([n3, n1, n2].sort).to eq([n1, n2, n3])
  end

  it "should share identity only with others of the same name" do
    n1 = Chef::Node.build("foo")
    n2 = Chef::Node.build("foo")
    n3 = Chef::Node.build("bar")
    expect(n1).to eq(n2)
    expect(n1).not_to eq(n3)
  end

  describe "when the node does not exist on the server" do
    before do
      response = OpenStruct.new(code: "404")
      exception = Net::HTTPClientException.new("404 not found", response)
      allow(Chef::Node).to receive(:load).and_raise(exception)
      node.name("created-node")
    end

    it "creates a new node for find_or_create" do
      allow(Chef::Node).to receive(:new).and_return(node)
      expect(node).to receive(:create).and_return(node)
      node = Chef::Node.find_or_create("created-node")
      expect(node.name).to eq("created-node")
      expect(node).to equal(node)
    end
  end

  describe "when the node exists on the server" do
    before do
      node.name("existing-node")
      allow(Chef::Node).to receive(:load).and_return(node)
    end

    it "loads the node via the REST API for find_or_create" do
      expect(Chef::Node.find_or_create("existing-node")).to equal(node)
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
      expect(n.chef_environment).to eq("_default")
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
      expect { node.name({}) }.to raise_error(ArgumentError)
    end

    it "cannot be blank" do
      expect { node.name("") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "should not accept name doesn't match /^[\-[:alnum:]_:.]+$/" do
      expect { node.name("space in it") }.to raise_error(Chef::Exceptions::ValidationFailed)
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
      expect { node.chef_environment({}) }.to raise_error(ArgumentError)
      expect { node.chef_environment(42) }.to raise_error(ArgumentError)
    end

    it "cannot be blank" do
      expect { node.chef_environment("") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "policy_name" do

    it "defaults to nil" do
      expect(node.policy_name).to be_nil
    end

    it "sets policy_name with a regular setter" do
      node.policy_name = "example-policy"
      expect(node.policy_name).to eq("example-policy")
    end

    it "allows policy_name with every valid character" do
      expect { node.policy_name = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqurstuvwxyz0123456789-_:." }.to_not raise_error
    end

    it "sets policy_name when given an argument" do
      node.policy_name("example-policy")
      expect(node.policy_name).to eq("example-policy")
    end

    it "sets policy_name to nil when given nil" do
      node.policy_name = "example-policy"
      node.policy_name = nil
      expect(node.policy_name).to be_nil
    end

    it "disallows non-strings" do
      expect { node.policy_name({}) }.to raise_error(Chef::Exceptions::ValidationFailed)
      expect { node.policy_name(42) }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "cannot be blank" do
      expect { node.policy_name("") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "policy_group" do

    it "defaults to nil" do
      expect(node.policy_group).to be_nil
    end

    it "sets policy_group with a regular setter" do
      node.policy_group = "staging"
      expect(node.policy_group).to eq("staging")
    end

    it "allows policy_group with every valid character" do
      expect { node.policy_group = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqurstuvwxyz0123456789-_:." }.to_not raise_error
    end

    it "sets a policy_group with policy_group(something)" do
      node.policy_group("staging")
      expect(node.policy_group).to eq("staging")
    end

    it "sets policy_group to nil when given nil" do
      node.policy_group = "staging"
      node.policy_group = nil
      expect(node.policy_group).to be_nil
    end

    it "disallows non-strings" do
      expect { node.policy_group({}) }.to raise_error(Chef::Exceptions::ValidationFailed)
      expect { node.policy_group(42) }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "cannot be blank" do
      expect { node.policy_group("") }.to raise_error(Chef::Exceptions::ValidationFailed)
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
      expect { node["secret"] = "shush" }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "should allow you to query whether an attribute exists with attribute?" do
      node.default["locust"] = "something"
      expect(node.attribute?("locust")).to eql(true)
      expect(node.attribute?("no dice")).to eql(false)
    end

    it "should let you go deep with attribute?" do
      node.normal["battles"]["people"]["wonkey"] = true
      expect(node["battles"]["people"].attribute?("wonkey")).to eq(true)
      expect(node["battles"]["people"].attribute?("snozzberry")).to eq(false)
    end

    it "does not allow modification of node attributes via hash methods" do
      node.default["h4sh"] = { foo: "bar" }
      expect { node["h4sh"].delete("foo") }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "does not allow modification of node attributes via array methods" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      node.default["array"] = []
      expect { node["array"] << "boom" }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "returns merged immutable attributes for arrays" do
      node.default["array"] = []
      expect( node["array"].class ).to eql(Chef::Node::ImmutableArray)
    end

    it "returns merged immutable attributes for hashes" do
      node.default["h4sh"] = {}
      expect( node["h4sh"].class ).to eql(Chef::Node::ImmutableMash)
    end

    describe "normal attributes" do
      it "should allow you to set an attribute with set, without pre-declaring a hash" do
        node.normal[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set an attribute with set_unless" do
        node.normal_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(false)
      end

      it "should not allow you to set an attribute with set_unless if it already exists" do
        node.normal[:snoopy][:is_a_puppy] = true
        node.normal_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should allow you to set an attribute with set_unless if is a nil value" do
        node.attributes.normal = { snoopy: { is_a_puppy: nil } }
        node.normal_unless[:snoopy][:is_a_puppy] = false
        expect(node[:snoopy][:is_a_puppy]).to eq(false)
      end

      it "should allow you to set a value after a set_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.normal_unless[:snoopy][:is_a_puppy] = false
        node.normal[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should let you set a value after a 'dangling' set_unless" do
        # this tests for set_unless_present state bleeding between statements CHEF-3806
        node.normal[:snoopy][:is_a_puppy] = "what"
        node.normal_unless[:snoopy][:is_a_puppy]
        node.normal[:snoopy][:is_a_puppy] = true
        expect(node[:snoopy][:is_a_puppy]).to eq(true)
      end

      it "should let you use tag as a convince method for the tags attribute" do
        node.normal["tags"] = %w{one two}
        node.tag("three", "four")
        expect(node["tags"]).to eq(%w{one two three four})
      end

      it "normal_unless sets a value even if default or override attrs are set" do
        node.default[:decontamination] = true
        node.override[:decontamination] = false
        node.normal_unless[:decontamination] = "foo"
        expect(node.normal[:decontamination]).to eql("foo")
      end

      it "default_unless sets a value even if normal or override attrs are set" do
        node.normal[:decontamination] = true
        node.override[:decontamination] = false
        node.default_unless[:decontamination] = "foo"
        expect(node.default[:decontamination]).to eql("foo")
      end

      it "override_unless sets a value even if default or normal attrs are set" do
        node.default[:decontamination] = true
        node.normal[:decontamination] = false
        node.override_unless[:decontamination] = "foo"
        expect(node.override[:decontamination]).to eql("foo")
      end

      it "consume_attributes does not exhibit chef/chef/issues/6302 bug" do
        node.normal["a"]["r1"] = nil
        node.consume_attributes({ "a" => { "r2" => nil } })
        expect(node["a"]["r1"]).to be_nil
        expect(node["a"]["r2"]).to be_nil
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

      it "does not exhibit chef/chef/issues/5005 bug" do
        node.env_default["a"]["r1"]["g"]["u"] = "u1"
        node.default_unless["a"]["r1"]["g"]["r"] = "r"
        expect(node["a"]["r1"]["g"]["u"]).to eql("u1")
      end

      it "default_unless correctly resets the deep merge cache" do
        node.normal["tags"] = []  # this sets our top-level breadcrumb
        node.default_unless["foo"]["bar"] = "NK-19V"
        expect(node["foo"]["bar"]).to eql("NK-19V")
        node.default_unless["foo"]["baz"] = "NK-33"
        expect(node["foo"]["baz"]).to eql("NK-33")
      end

      it "normal_unless correctly resets the deep merge cache" do
        node.normal["tags"] = []  # this sets our top-level breadcrumb
        node.normal_unless["foo"]["bar"] = "NK-19V"
        expect(node["foo"]["bar"]).to eql("NK-19V")
        node.normal_unless["foo"]["baz"] = "NK-33"
        expect(node["foo"]["baz"]).to eql("NK-33")
      end

      it "override_unless correctly resets the deep merge cache" do
        node.normal["tags"] = []  # this sets our top-level breadcrumb
        node.override_unless["foo"]["bar"] = "NK-19V"
        expect(node["foo"]["bar"]).to eql("NK-19V")
        node.override_unless["foo"]["baz"] = "NK-33"
        expect(node["foo"]["baz"]).to eql("NK-33")
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
    end

    describe "globally deleting attributes" do
      context "with hash values" do
        before do
          node.role_default["mysql"]["server"]["port"] = 1234
          node.normal["mysql"]["server"]["port"] = 2345
          node.override["mysql"]["server"]["port"] = 3456
        end

        it "deletes all the values and returns the value with the highest precedence" do
          expect( node.rm("mysql", "server", "port") ).to eql(3456)
          expect( node["mysql"]["server"]["port"] ).to be_nil
          expect( node["mysql"]["server"] ).to eql({})
        end

        it "deletes nested things correctly" do
          node.default["mysql"]["client"]["client_setting"] = "foo"
          expect( node.rm("mysql", "server") ).to eql( { "port" => 3456 } )
          expect( node["mysql"] ).to eql( { "client" => { "client_setting" => "foo" } } )
        end

        it "returns nil if the node attribute does not exist" do
          expect( node.rm("no", "such", "thing") ).to be_nil
        end

        it "can delete the entire tree" do
          expect( node.rm("mysql") ).to eql({ "server" => { "port" => 3456 } })
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

        it "when mistaking arrays for hashes, it considers the value removed and does nothing" do
          node.rm("mysql", "server", "port")
          expect(node["mysql"]["server"][0]["port"]).to eql(3456)
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

        it "returns nil for the combined attributes" do
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

      it "replaces a value at the cookbook sub-level of the attributes only" do
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
    # https://github.com/chef/chef/issues/2700
    # https://github.com/chef/chef/issues/2712
    # https://github.com/chef/chef/issues/2745
    #
    describe "deep merge attribute cache edge conditions" do
      it "does not error with complicated attribute substitution" do
        node.default["chef_attribute_hell"]["attr1"] = "attribute1"
        node.default["chef_attribute_hell"]["attr2"] = "#{node[:chef_attribute_hell][:attr1]}/attr2"
        expect { node.default["chef_attribute_hell"]["attr3"] = "#{node[:chef_attribute_hell][:attr2]}/attr3" }.not_to raise_error
      end

      it "caches both strings and symbols correctly" do
        node.force_default[:solr][:version] = "4.10.2"
        node.force_default[:solr][:data_dir] = "/opt/solr-#{node["solr"][:version]}/example/solr"
        node.force_default[:solr][:xms] = "512M"
        expect(node[:solr][:xms]).to eql("512M")
        expect(node["solr"][:xms]).to eql("512M")
      end

      it "method interpolation syntax also works" do
        Chef::Config[:treat_deprecation_warnings_as_errors] = false
        node.default["passenger"]["version"]     = "4.0.57"
        node.default["passenger"]["root_path"]   = "passenger-#{node["passenger"]["version"]}"
        node.default["passenger"]["root_path_2"] = "passenger-#{node[:passenger]["version"]}"
        expect(node["passenger"]["root_path_2"]).to eql("passenger-4.0.57")
        expect(node[:passenger]["root_path_2"]).to eql("passenger-4.0.57")
      end
    end

    it "should raise an ArgumentError if you ask for an attribute that doesn't exist via method_missing" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      expect { node.sunshine }.to raise_error(NoMethodError)
    end

    it "should allow you to iterate over attributes with each_attribute" do
      node.default["sunshine"] = "is bright"
      node.default["canada"] = "is a nice place"
      seen_attributes = {}
      node.each_attribute do |a, v|
        seen_attributes[a] = v
      end
      expect(seen_attributes).to have_key("sunshine")
      expect(seen_attributes).to have_key("canada")
      expect(seen_attributes["sunshine"]).to eq("is bright")
      expect(seen_attributes["canada"]).to eq("is a nice place")
    end

    describe "functional attribute API" do
      # deeper functional testing of this API is in the VividMash spec tests
      it "should have an exist? function" do
        node.default["foo"]["bar"] = "baz"
        expect(node.exist?("foo", "bar")).to be true
        expect(node.exist?("bar", "foo")).to be false
      end

      it "should have a read function" do
        node.override["foo"]["bar"] = "baz"
        expect(node.read("foo", "bar")).to eql("baz")
        expect(node.read("bar", "foo")).to eql(nil)
      end

      it "should have a read! function" do
        node.override["foo"]["bar"] = "baz"
        expect(node.read!("foo", "bar")).to eql("baz")
        expect { node.read!("bar", "foo") }.to raise_error(Chef::Exceptions::NoSuchAttribute)
      end

      it "delegates write(:level) to node.level.write()" do
        node.write(:default, "foo", "bar", "baz")
        expect(node.default["foo"]["bar"]).to eql("baz")
      end

      it "delegates write!(:level) to node.level.write!()" do
        node.write!(:default, "foo", "bar", "baz")
        expect(node.default["foo"]["bar"]).to eql("baz")
        node.default["bar"] = true
        expect { node.write!(:default, "bar", "foo", "baz") }.to raise_error(Chef::Exceptions::AttributeTypeMismatch)
      end

      it "delegates unlink(:level) to node.level.unlink()" do
        node.default["foo"]["bar"] = "baz"
        expect(node.unlink(:default, "foo", "bar")).to eql("baz")
        expect(node.unlink(:default, "bar", "foo")).to eql(nil)
      end

      it "delegates unlink!(:level) to node.level.unlink!()" do
        node.default["foo"]["bar"] = "baz"
        expect(node.unlink!(:default, "foo", "bar")).to eql("baz")
        expect { node.unlink!(:default, "bar", "foo") }.to raise_error(Chef::Exceptions::NoSuchAttribute)
      end
    end
  end

  describe "consuming json" do

    before do
      @ohai_data = { platform: "foo", platform_version: "bar" }
    end

    it "consumes the run list portion of a collection of attributes and returns the remainder" do
      attrs = { "run_list" => [ "role[base]", "recipe[chef::server]" ], "foo" => "bar" }
      expect(node.consume_run_list(attrs)).to eq({ "foo" => "bar" })
      expect(node.run_list).to eq([ "role[base]", "recipe[chef::server]" ])
    end

    it "sets the node chef_environment" do
      attrs = { "chef_environment" => "foo_environment", "bar" => "baz" }
      expect(node.consume_chef_environment(attrs)).to eq({ "bar" => "baz" })
      expect(node.chef_environment).to eq("foo_environment")
      expect(node["chef_environment"]).to be nil
    end

    it "should overwrites the run list with the run list it consumes" do
      node.consume_run_list "recipes" => %w{one two}
      node.consume_run_list "recipes" => [ "three" ]
      expect(node.run_list).to eq([ "three" ])
    end

    it "should not add duplicate recipes from the json attributes" do
      node.run_list << "one"
      node.consume_run_list "recipes" => %w{one two three}
      expect(node.run_list).to eq(%w{one two three})
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
      node.consume_external_attrs(@ohai_data, { "one" => "two", "three" => "four" })
      expect(node["one"]).to eql("two")
      expect(node["three"]).to eql("four")
    end

    it "should set the tags attribute to an empty array if it is not already defined" do
      node.consume_external_attrs(@ohai_data, {})
      expect(node.tags).to eql([])
    end

    it "should not set the tags attribute to an empty array if it is already defined" do
      node.tag("radiohead")
      node.consume_external_attrs(@ohai_data, {})
      expect(node.tags).to eql([ "radiohead" ])
    end

    it "should set the tags attribute to an empty array if it is nil" do
      node.attributes.normal = { "tags" => nil }
      node.consume_external_attrs(@ohai_data, {})
      expect(node.tags).to eql([])
    end

    it "should return an array if it is fed a string" do
      node.normal[:tags] = "string"
      node.consume_external_attrs(@ohai_data, {})
      expect(node.tags).to eql(["string"])
    end

    it "should return an array if it is fed a hash" do
      node.normal[:tags] = {}
      node.consume_external_attrs(@ohai_data, {})
      expect(node.tags).to eql([])
    end

    it "deep merges attributes instead of overwriting them" do
      node.consume_external_attrs(@ohai_data, "one" => { "two" => { "three" => "four" } })
      expect(node["one"].to_hash).to eq({ "two" => { "three" => "four" } })
      node.consume_external_attrs(@ohai_data, "one" => { "abc" => "123" })
      node.consume_external_attrs(@ohai_data, "one" => { "two" => { "foo" => "bar" } })
      expect(node["one"].to_hash).to eq({ "two" => { "three" => "four", "foo" => "bar" }, "abc" => "123" })
    end

    it "gives attributes from JSON priority when deep merging" do
      node.consume_external_attrs(@ohai_data, "one" => { "two" => { "three" => "four" } })
      expect(node["one"].to_hash).to eq({ "two" => { "three" => "four" } })
      node.consume_external_attrs(@ohai_data, "one" => { "two" => { "three" => "forty-two" } })
      expect(node["one"].to_hash).to eq({ "two" => { "three" => "forty-two" } })
    end

    it "converts the platform_version to a Chef::VersionString" do
      node.consume_external_attrs(@ohai_data, {})
      expect(node["platform_version"]).to be_kind_of(Chef::VersionString)
    end
  end

  describe "merging ohai data" do
    before do
      @ohai_data = { platform: "foo", platform_version: "bar" }
    end

    it "converts the platform_version to a Chef::VersionString" do
      node.consume_external_attrs(@ohai_data, {})
      node.consume_ohai_data({ "platform_version" => "6.3" })
      expect(node["platform_version"]).to be_kind_of(Chef::VersionString)
      expect(node["platform_version"] =~ "~> 6.1").to be true
    end
  end

  describe "preparing for a chef client run" do
    before do
      @ohai_data = { platform: "foobuntu", platform_version: "23.42" }
    end

    it "sets its platform according to platform detection" do
      node.consume_external_attrs(@ohai_data, {})
      expect(node.automatic_attrs[:platform]).to eq("foobuntu")
      expect(node.automatic_attrs[:platform_version]).to eq("23.42")
    end

    it "consumes the run list from provided json attributes" do
      node.consume_external_attrs(@ohai_data, { "run_list" => ["recipe[unicorn]"] })
      expect(node.run_list).to eq(["recipe[unicorn]"])
    end

    it "saves non-runlist json attrs for later" do
      expansion = Chef::RunList::RunListExpansion.new("_default", [])
      allow(node.run_list).to receive(:expand).and_return(expansion)
      node.consume_external_attrs(@ohai_data, { "foo" => "bar" })
      node.expand!
      expect(node.normal_attrs).to eq({ "foo" => "bar", "tags" => [] })
    end

    it "converts the platform_version to a Chef::VersionString" do
      node.consume_external_attrs(@ohai_data, {})
      expect(node.automatic_attrs[:platform_version]).to be_a_kind_of(Chef::VersionString)
      expect(node[:platform_version]).to be_a_kind_of(Chef::VersionString)
      expect(node[:platform_version] =~ "~> 23.6").to be true
    end

  end

  describe "when expanding its run list and merging attributes" do
    before do
      @environment = Chef::Environment.new.tap do |e|
        e.name("rspec_env")
        e.default_attributes("env default key" => "env default value")
        e.override_attributes("env override key" => "env override value")
      end
      expect(Chef::Environment).to receive(:load).with("rspec_env").and_return(@environment)
      @expansion = Chef::RunList::RunListExpansion.new("rspec_env", [])
      node.chef_environment("rspec_env")
      allow(node.run_list).to receive(:expand).and_return(@expansion)
    end

    it "sets the 'recipes' automatic attribute to the recipes in the expanded run_list" do
      @expansion.recipes << "recipe[chef::client]" << "recipe[nginx::default]"
      node.expand!
      expect(node.automatic_attrs[:recipes]).to eq(["recipe[chef::client]", "recipe[nginx::default]"])
    end

    it "sets the 'roles' automatic attribute to the expanded role list" do
      @expansion.instance_variable_set(:@applied_roles, { "arf" => nil, "countersnark" => nil })
      node.expand!
      expect(node.automatic_attrs[:roles].sort).to eq(%w{arf countersnark})
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
      @expansion.default_attrs.replace({ default: "from role", d_role: "role only" })
      @expansion.override_attrs.replace({ override: "from role", o_role: "role only" })

      @environment = Chef::Environment.new
      @environment.default_attributes = { default: "from env", d_env: "env only" }
      @environment.override_attributes = { override: "from env", o_env: "env only" }
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
      expect(node["ldap_server"]).to eql("ops1prod")
      expect(node["ldap_basedn"]).to eql("dc=hjksolutions,dc=com")
      expect(node["ldap_replication_password"]).to eql("forsure")
      expect(node["smokey"]).to eql("robinson")
    end

    it "gives a sensible error when attempting to load a missing attributes file" do
      expect { node.include_attribute("nope-this::doesnt-exist") }.to raise_error(Chef::Exceptions::CookbookNotFound)
    end
  end

  describe "roles" do
    it "should allow you to query whether or not it has a recipe applied with role?" do
      node.automatic["roles"] = %w{sunrise}
      expect(node.role?("sunrise")).to eql(true)
      expect(node.role?("not at home")).to eql(false)
    end

    it "should allow you to set roles with arguments" do
      node.automatic["roles"] = %w{one two}
      expect(node.role?("one")).to eql(true)
      expect(node.role?("two")).to eql(true)
      expect(node.role?("three")).to eql(false)
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
      expect(node["sunshine"]).to eql("in")
      expect(node["something"]).to eql("else")
      expect(node.run_list).to eq(%w{operations-master operations-monitoring})
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

      @example = Chef::Node.new
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

    it "should return an empty array for empty run_list" do
      expect(node.to_hash["run_list"]).to eq([])
    end
  end

  describe "converting to or from json" do
    it "should serialize itself as json", json: true do
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

    it "should serialize valid json with a run list", json: true do
      # This test came about because activesupport mucks with Chef json serialization
      # Test should pass with and without Activesupport
      node.run_list << { "type" => "role", "name" => "Cthulu" }
      node.run_list << { "type" => "role", "name" => "Hastur" }
      json = Chef::JSONCompat.to_json(node)
      expect(json).to match(/\"run_list\":\[\"role\[Cthulu\]\",\"role\[Hastur\]\"\]/)
    end

    it "should serialize the correct run list", json: true do
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

    it "should deserialize itself from json", json: true do
      node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
      json = Chef::JSONCompat.to_json(node)
      serialized_node = Chef::Node.from_hash(Chef::JSONCompat.parse(json))
      expect(serialized_node).to be_a_kind_of(Chef::Node)
      expect(serialized_node.name).to eql(node.name)
      expect(serialized_node.chef_environment).to eql(node.chef_environment)
      node.each_attribute do |k, v|
        expect(serialized_node[k]).to eql(v)
      end
      expect(serialized_node.run_list).to eq(node.run_list)
    end

    context "when policyfile attributes are not present" do

      it "does not have a policy_name key in the json" do
        expect(node.for_json.keys).to_not include("policy_name")
      end

      it "does not have a policy_group key in the json" do
        expect(node.for_json.keys).to_not include("policy_name")
      end
    end

    context "when policyfile attributes are present" do

      before do
        node.policy_name = "my-application"
        node.policy_group = "staging"
      end

      it "includes policy_name key in the json" do
        expect(node.for_json).to have_key("policy_name")
        expect(node.for_json["policy_name"]).to eq("my-application")
      end

      it "includes a policy_group key in the json" do
        expect(node.for_json).to have_key("policy_group")
        expect(node.for_json["policy_group"]).to eq("staging")
      end

      it "parses policyfile attributes from JSON" do
        round_tripped_node = Chef::Node.from_hash(node.for_json)

        expect(round_tripped_node.policy_name).to eq("my-application")
        expect(round_tripped_node.policy_group).to eq("staging")
        expect(round_tripped_node.chef_environment).to eq("staging")
      end

    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) do
        node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
        node
      end
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
      @rest = double("Chef::ServerAPI")
      allow(Chef::ServerAPI).to receive(:new).and_return(@rest)
      @query = double("Chef::Search::Query")
      allow(Chef::Search::Query).to receive(:new).and_return(@query)
    end

    describe "list" do
      describe "inflated" do
        it "should return a hash of node names and objects" do
          n1 = double("Chef::Node", name: "one")
          allow(n1).to receive(:is_a?).with(Chef::Node) { true }
          expect(@query).to receive(:search).with(:node).and_yield(n1)
          r = Chef::Node.list(true)
          expect(r["one"]).to eq(n1)
        end
      end

      it "should return a hash of node names and urls" do
        expect(@rest).to receive(:get).and_return({ "one" => "http://foo" })
        r = Chef::Node.list
        expect(r["one"]).to eq("http://foo")
      end
    end

    describe "load" do
      it "should load a node by name" do
        node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
        json = Chef::JSONCompat.to_json(node)
        parsed = Chef::JSONCompat.parse(json)
        expect(@rest).to receive(:get).with("nodes/test.example.com").and_return(parsed)
        serialized_node = Chef::Node.load("test.example.com")
        expect(serialized_node).to be_a_kind_of(Chef::Node)
        expect(serialized_node.name).to eql(node.name)
      end
    end

    describe "destroy" do
      it "should destroy a node" do
        expect(@rest).to receive(:delete).with("nodes/monkey").and_return("foo")
        node.name("monkey")
        node.destroy
      end
    end

    describe "save" do
      it "should update a node if it already exists" do
        node.name("monkey")
        allow(node).to receive(:data_for_save).and_return({})
        expect(@rest).to receive(:put).with("nodes/monkey", {}).and_return("foo")
        node.save
      end

      it "should not try and create if it can update" do
        node.name("monkey")
        allow(node).to receive(:data_for_save).and_return({})
        expect(@rest).to receive(:put).with("nodes/monkey", {}).and_return("foo")
        expect(@rest).not_to receive(:post)
        node.save
      end

      it "should create if it cannot update" do
        node.name("monkey")
        allow(node).to receive(:data_for_save).and_return({})
        exception = double("404 error", code: "404")
        expect(@rest).to receive(:put).and_raise(Net::HTTPClientException.new("foo", exception))
        expect(@rest).to receive(:post).with("nodes", {})
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
          expect(@rest).not_to receive(:put)
          expect(@rest).not_to receive(:post)
          node.save
        end
      end

      context "with allowed attributes configured" do
        it "should only save allowed attributes (and subattributes)" do
          Chef::Config[:allowed_default_attributes] = [
            ["filesystem", "/dev/disk0s2"],
            "network/interfaces/eth0",
          ]

          node.default = {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {},
                  "eth1" => {},
                },
              },
            }
          node.automatic = {}
          node.normal = {}
          node.override = {}

          selected_data = {
            "default" => {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {},
                },
              },
            },
            "automatic" => {}, "normal" => {}, "override" => {}
          }

          node.name("picky-monkey")
          expect(@rest).to receive(:put).with("nodes/picky-monkey", hash_including(selected_data)).and_return("foo")
          node.save
        end

        it "should save false-y allowed attributes" do
          Chef::Config[:allowed_default_attributes] = [
            "foo/bar/baz",
          ]

          node.default = {
              "foo" => {
                "bar" => {
                  "baz" => false,
                },
                "other" => {
                  "stuff" => true,
                },
              },
            }

          node.automatic = {}
          node.normal = {}
          node.override = {}

          selected_data = {
            "default" => {
              "foo" => {
                "bar" => {
                  "baz" => false,
                },
              },
            },
          }

          node.name("falsey-monkey")
          expect(@rest).to receive(:put).with("nodes/falsey-monkey", hash_including(selected_data)).and_return("foo")
          node.save
        end

        it "should not save any attributes if the allowed is empty" do
          Chef::Config[:allowed_default_attributes] = []

          node.default = {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" },
              },
            }
          node.automatic = {}
          node.normal = {}
          node.override = {}

          selected_data = {
            "automatic" => {}, "default" => {}, "normal" => {}, "override" => {}
          }

          node.name("picky-monkey")
          expect(@rest).to receive(:put).with("nodes/picky-monkey", hash_including(selected_data)).and_return("foo")
          node.save
        end
      end

      context "with deprecated whitelist attributes configured" do
        it "should only save allowed attributes (and subattributes)" do
          Chef::Config[:default_attribute_whitelist] = [
            ["filesystem", "/dev/disk0s2"],
            "network/interfaces/eth0",
          ]

          node.default = {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {},
                  "eth1" => {},
                },
              },
            }
          node.automatic = {}
          node.normal = {}
          node.override = {}

          selected_data = {
            "default" => {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {},
                },
              },
            },
            "automatic" => {}, "normal" => {}, "override" => {}
          }

          node.name("picky-monkey")
          Chef::Config[:treat_deprecation_warnings_as_errors] = false
          expect(@rest).to receive(:put).with("nodes/picky-monkey", hash_including(selected_data)).and_return("foo")
          node.save
        end
      end

      context "with deprecated blacklist attributes configured" do
        it "should only save non-blocklisted attributes (and subattributes)" do
          Chef::Config[:default_attribute_blacklist] = [
            ["filesystem", "/dev/disk0s2"],
            "network/interfaces/eth0",
          ]

          node.default = {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {},
                  "eth1" => {},
                },
              },
            }
          node.automatic = {}
          node.normal = {}
          node.override = {}

          selected_data = {
            "default" => {
              "filesystem" => {
                "map - autohome" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth1" => {},
                },
              },
            },
            "automatic" => {}, "normal" => {}, "override" => {}
          }
          node.name("picky-monkey")
          Chef::Config[:treat_deprecation_warnings_as_errors] = false
          expect(@rest).to receive(:put).with("nodes/picky-monkey", hash_including(selected_data)).and_return("foo")
          node.save
        end
      end

      context "with blocklisted attributes configured" do
        it "should only save non-blocklisted attributes (and subattributes)" do
          Chef::Config[:blocked_default_attributes] = [
            ["filesystem", "/dev/disk0s2"],
            "network/interfaces/eth0",
          ]

          node.default = {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth0" => {},
                  "eth1" => {},
                },
              },
            }
          node.automatic = {}
          node.normal = {}
          node.override = {}

          selected_data = {
            "default" => {
              "filesystem" => {
                "map - autohome" => { "size" => "10mb" },
              },
              "network" => {
                "interfaces" => {
                  "eth1" => {},
                },
              },
            },
            "automatic" => {}, "normal" => {}, "override" => {}
          }
          node.name("picky-monkey")
          expect(@rest).to receive(:put).with("nodes/picky-monkey", hash_including(selected_data)).and_return("foo")
          node.save
        end

        it "should save all attributes if the blocklist is empty" do
          Chef::Config[:blocked_default_attributes] = []

          node.default = {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" },
              },
            }
          node.automatic = {}
          node.normal = {}
          node.override = {}

          selected_data = {
            "default" => {
              "filesystem" => {
                "/dev/disk0s2" => { "size" => "10mb" },
                "map - autohome" => { "size" => "10mb" },
              },
            },
            "automatic" => {}, "normal" => {}, "override" => {}
          }

          node.name("picky-monkey")
          expect(@rest).to receive(:put).with("nodes/picky-monkey", hash_including(selected_data)).and_return("foo")
          node.save
        end
      end

      context "when policyfile attributes are present" do

        before do
          node.name("example-node")
          node.policy_name = "my-application"
          node.policy_group = "staging"
        end

        context "and the server supports policyfile attributes in node JSON" do

          it "creates the object normally" do
            expect(@rest).to receive(:post).with("nodes", node.for_json)
            node.create
          end

          it "saves the node object normally" do
            expect(@rest).to receive(:put).with("nodes/example-node", node.for_json)
            node.save
          end
        end

        # Chef Server before 12.3
        context "and the Chef Server does not support policyfile attributes in node JSON" do

          let(:response_body) { %q[{"error":["Invalid key policy_name in request body"]}] }

          let(:response) do
            Net::HTTPResponse.send(:response_class, "400").new("1.0", "400", "Bad Request").tap do |r|
              allow(r).to receive(:body).and_return(response_body)
            end
          end

          let(:http_exception) do

            response.error!
          rescue => e
            e

          end

          let(:trimmed_node) do
            node.for_json.tap do |j|
              j.delete("policy_name")
              j.delete("policy_group")
            end

          end

          it "lets the 400 pass through" do
            expect(@rest).to receive(:put).and_raise(http_exception)
            expect { node.save }.to raise_error(http_exception)
          end

        end

      end

    end
  end

  describe "method_missing handling" do
    it "should have an #empty? method via Chef::Node::Attribute" do
      node.default["foo"] = "bar"
      expect(node.empty?).to be false
    end

    it "it should correctly implement #respond_to?" do
      expect(node.respond_to?(:empty?)).to be true
    end

    it "it should correctly retrieve the method with #method" do
      expect(node.method(:empty?)).to be_kind_of(Method)
    end
  end

  describe "path tracking via __path__" do
    it "works through hash keys" do
      node.default["foo"] = { "bar" => { "baz" => "qux" } }
      expect(node["foo"]["bar"].__path__).to eql(%w{foo bar})
    end

    it "works through the default level" do
      node.default["foo"] = { "bar" => { "baz" => "qux" } }
      expect(node.default["foo"]["bar"].__path__).to eql(%w{foo bar})
    end

    it "works through arrays" do
      node.default["foo"] = [ { "bar" => { "baz" => "qux" } } ]
      expect(node["foo"][0].__path__).to eql(["foo", 0])
      expect(node["foo"][0]["bar"].__path__).to eql(["foo", 0, "bar"])
    end

    it "works through arrays at the default level" do
      node.default["foo"] = [ { "bar" => { "baz" => "qux" } } ]
      expect(node.default["foo"][0].__path__).to eql(["foo", 0])
      expect(node.default["foo"][0]["bar"].__path__).to eql(["foo", 0, "bar"])
    end

    # if we set __path__ in the initializer we'd get this wrong, this is why we
    # update the path on every #[] or #[]= operator
    it "works on access when the node has been rearranged" do
      node.default["foo"] = { "bar" => { "baz" => "qux" } }
      a = node.default["foo"]
      node.default["fizz"] = a
      expect(node["fizz"]["bar"].__path__).to eql(%w{fizz bar})
      expect(node["foo"]["bar"].__path__).to eql(%w{foo bar})
    end

    # We have a problem because the __path__ is stored on in each node, but the
    # node can be wired up at multiple locations in the tree via pointers.  One
    # solution would be to deep-dup the value in `#[]=(key, value)` and fix the
    # __path__ on all the dup'd nodes.  The problem is that this would create an
    # unusual situation where after assignment, you couldn't mutate the thing you
    # hand a handle on.  I'm not entirely positive this behavior is the correct
    # thing to support, but it is more hash-like (although if we start with a hash
    # then convert_value does its thing and we *do* get dup'd on assignment).  This
    # behavior likely makes any implementation of a deep merge cache built over the
    # top of __path__ tracking have edge conditions where it will fail.
    #
    # Removing this support would be a breaking change.  The test is included here
    # because it seems most likely that someone would break this behavior while trying
    # to fix __path__ behavior.
    it "does not dup in the background when a node is assigned" do
      # get a handle on a vividmash (can't be a hash or else we convert_value it)
      node.default["foo"] = { "bar" => { "baz" => "qux" } }
      a = node.default["foo"]
      # assign that somewhere else in the tree
      node.default["fizz"] = a
      # now update the source
      a["duptest"] = true
      # the tree should have been updated
      expect(node.default["fizz"]["duptest"]).to be true
      expect(node["fizz"]["duptest"]).to be true
    end
  end

  describe "root tracking via __root__" do
    it "works through hash keys" do
      node.default["foo"] = { "bar" => { "baz" => "qux" } }
      expect(node["foo"]["bar"].__root__).to eql(node.attributes)
    end

    it "works through the default level" do
      node.default["foo"] = { "bar" => { "baz" => "qux" } }
      expect(node.default["foo"]["bar"].__root__).to eql(node.attributes)
    end

    it "works through arrays" do
      node.default["foo"] = [ { "bar" => { "baz" => "qux" } } ]
      expect(node["foo"][0].__root__).to eql(node.attributes)
      expect(node["foo"][0]["bar"].__root__).to eql(node.attributes)
    end

    it "works through arrays at the default level" do
      node.default["foo"] = [ { "bar" => { "baz" => "qux" } } ]
      expect(node.default["foo"][0].__root__).to eql(node.attributes)
      expect(node.default["foo"][0]["bar"].__root__).to eql(node.attributes)
    end
  end

  describe "ways of abusing Chef 12 node state" do
    # these tests abuse the top_level_breadcrumb state in Chef 12
    it "derived attributes work correctly" do
      node.default["v1"] = 1
      expect(node["a"]).to eql(nil)
      node.default["a"] = node["v1"]
      expect(node["a"]).to eql(1)
    end

    it "works when saving nodes to variables" do
      a = node.default["a"]
      expect(node["a"]).to eql({})
      node.default["b"] = 0
      a["key"] = 1

      expect(node["a"]["key"]).to eql(1)
    end
  end

  describe "when abusing the deep merge cache" do
    # https://github.com/chef/chef/issues/7738
    it "do not corrupt VividMashes that are part of the merge set and not the merge_onto set" do
      # need to have a merge two-deep (not at the top-level) between at least two default (or two override)
      # levels where the lowest priority one is the one that is going to be corrupted
      node.default["foo"]["bar"]["baz"] = "fizz"
      node.env_default["foo"]["bar"]["quux"] = "buzz"
      node.default["foo"]["bar"].tap do |bar|
        bar["test"] = "wrong"
        # this triggers a deep merge
        node["foo"]["bar"]["test"]
        # this should correctly write and dirty the cache so the next read does another deep merge on the correct __root__
        bar["test"] = "right"
      end
      expect(node["foo"]["bar"]["test"]).to eql("right")
    end

    it "do not corrupt VividMashes that are part of the merge set and not the merge_onto set (when priorities are reversed)" do
      # need to have a merge two-deep (not at the top-level) between at least two default (or two override)
      # levels where the *HIGHEST* priority one is the one that is going to be corrupted
      node.env_default["foo"]["bar"]["baz"] = "fizz"
      node.default["foo"]["bar"]["quux"] = "buzz"
      node.env_default["foo"]["bar"].tap do |bar|
        bar["test"] = "wrong"
        # this triggers a deep merge
        node["foo"]["bar"]["test"]
        # this should correctly write and dirty the cache so the next read does another deep merge on the correct __root__
        bar["test"] = "right"
      end
      expect(node["foo"]["bar"]["test"]).to eql("right")
    end
  end

  describe "lazy values" do
    it "supports lazy values in attributes" do
      node.instance_eval do
        default["foo"]["bar"] = lazy { node["fizz"]["buzz"] }
        default["fizz"]["buzz"] = "works"
      end
      expect(node["foo"]["bar"]).to eql("works")
    end

    it "lazy values maintain laziness" do
      node.instance_eval do
        default["foo"]["bar"] = lazy { node["fizz"]["buzz"] }
        default["fizz"]["buzz"] = "works"
      end
      expect(node["foo"]["bar"]).to eql("works")
      node.default["fizz"]["buzz"] = "still works"
      expect(node["foo"]["bar"]).to eql("still works")
    end

    it "supports recursive lazy values in attributes" do
      node.instance_eval do
        default["cool"]["beans"] = lazy { node["foo"]["bar"] }
        default["foo"]["bar"] = lazy { node["fizz"]["buzz"] }
        default["fizz"]["buzz"] = "works"
      end
      expect(node["cool"]["beans"]).to eql("works")
      node.default["fizz"]["buzz"] = "still works"
      expect(node["cool"]["beans"]).to eql("still works")
    end

    it "supports top level lazy values in attributes" do
      # due to the top level deep merge cache these are special cases
      node.instance_eval do
        default["cool"] = lazy { node["foo"] }
        default["foo"] = lazy { node["fizz"] }
        default["fizz"] = "works"
      end
      expect(node["cool"]).to eql("works")
      node.default["fizz"] = "still works"
      expect(node["cool"]).to eql("still works")
    end

    it "supports deep merged values in attributes" do
      node.instance_eval do
        override["bar"]["cool"] = lazy { node["bar"]["foo"] }
        override["bar"]["foo"] = lazy { node["bar"]["fizz"] }
        override["bar"]["fizz"] = "works"
      end
      expect(node["bar"]["cool"]).to eql("works")
      node.override["bar"]["fizz"] = "still works"
      expect(node["bar"]["cool"]).to eql("still works")
    end

    it "supports overridden deep merged values in attributes (deep_merge)" do
      node.instance_eval do
        role_override["bar"] = { "cool" => "bad", "foo" => "bad", "fizz" => "bad" }
        force_override["bar"]["cool"] = lazy { node["bar"]["foo"] }
        force_override["bar"]["foo"] = lazy { node["bar"]["fizz"] }
        force_override["bar"]["fizz"] = "works"
      end
      expect(node["bar"]["cool"]).to eql("works")
      node.force_override["bar"]["fizz"] = "still works"
      expect(node["bar"]["cool"]).to eql("still works")
    end

    it "supports overridden deep merged values in attributes (hash_only_merge)" do
      node.instance_eval do
        default["bar"] = { "cool" => "bad", "foo" => "bad", "fizz" => "bad" }
        override["bar"]["cool"] = lazy { node["bar"]["foo"] }
        override["bar"]["foo"] = lazy { node["bar"]["fizz"] }
        override["bar"]["fizz"] = "works"
      end
      expect(node["bar"]["cool"]).to eql("works")
      node.override["bar"]["fizz"] = "still works"
      expect(node["bar"]["cool"]).to eql("still works")
    end
  end
end
