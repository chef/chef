#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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
require "chef/policy_builder"

describe Chef::PolicyBuilder::ExpandNodeObject do

  let(:node_name) { "joe_node" }
  let(:ohai_data) { { "platform" => "ubuntu", "platform_version" => "13.04", "fqdn" => "joenode.example.com" } }
  let(:json_attribs) { { "run_list" => [] } }
  let(:override_runlist) { "recipe[foo::default]" }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:policy_builder) { Chef::PolicyBuilder::ExpandNodeObject.new(node_name, ohai_data, json_attribs, override_runlist, events) }

  # All methods that Chef::Client calls on this class.
  describe "Public API" do
    it "implements a node method" do
      expect(policy_builder).to respond_to(:node)
    end

    it "has removed the deprecated #load_node method" do
      expect(policy_builder).to_not respond_to(:load_node)
    end

    it "implements a finish_load_node method" do
      expect(policy_builder).to respond_to(:finish_load_node)
    end

    it "implements  a build_node method" do
      expect(policy_builder).to respond_to(:build_node)
    end

    it "implements a setup_run_context method that accepts a list of recipe files to run" do
      expect(policy_builder).to respond_to(:setup_run_context)
      expect(policy_builder.method(:setup_run_context).arity).to eq(-1) #optional argument
    end

    it "implements a run_context method" do
      expect(policy_builder).to respond_to(:run_context)
    end

    it "implements an expand_run_list method" do
      expect(policy_builder).to respond_to(:expand_run_list)
    end

    it "implements a sync_cookbooks method" do
      expect(policy_builder).to respond_to(:sync_cookbooks)
    end

    it "implements a temporary_policy? method" do
      expect(policy_builder).to respond_to(:temporary_policy?)
    end

    describe "finishing loading the node" do

      let(:node) { Chef::Node.new.tap { |n| n.name(node_name) } }

      it "stores the node" do
        policy_builder.finish_load_node(node)
        expect(policy_builder.node).to eq(node)
      end

    end

  end

  # Implementation specific tests

  describe "when first created" do

    it "has a node_name" do
      expect(policy_builder.node_name).to eq(node_name)
    end

    it "has ohai data" do
      expect(policy_builder.ohai_data).to eq(ohai_data)
    end

    it "has a set of attributes from command line option" do
      expect(policy_builder.json_attribs).to eq(json_attribs)
    end

    it "has an override_runlist" do
      expect(policy_builder.override_runlist).to eq(override_runlist)
    end

  end

  context "once the node has been loaded" do
    let(:node) do
      node = Chef::Node.new
      node.name(node_name)
      node.run_list(["recipe[a::default]", "recipe[b::server]"])
      node
    end

    before do
      policy_builder.finish_load_node(node)
    end

    it "expands the run_list" do
      expect(policy_builder.expand_run_list).to be_a(Chef::RunList::RunListExpansion)
      expect(policy_builder.run_list_expansion).to be_a(Chef::RunList::RunListExpansion)
      expect(policy_builder.run_list_expansion.recipes).to eq(["a::default", "b::server"])
    end

  end

  describe "building the node" do

    let(:configured_environment) { nil }
    let(:json_attribs) { nil }

    let(:override_runlist) { nil }
    let(:primary_runlist) { ["recipe[primary::default]"] }

    let(:original_default_attrs) { { "default_key" => "default_value" } }
    let(:original_override_attrs) { { "override_key" => "override_value" } }

    let(:node) do
      node = Chef::Node.new
      node.name(node_name)
      node.default_attrs = original_default_attrs
      node.override_attrs = original_override_attrs
      node.run_list(primary_runlist)
      node
    end

    before do
      Chef::Config[:environment] = configured_environment
      policy_builder.finish_load_node(node)
      policy_builder.build_node
    end

    it "sanity checks test setup" do
      expect(node.run_list).to eq(primary_runlist)
    end

    it "clears existing default and override attributes from the node" do
      expect(node["default_key"]).to be_nil
      expect(node["override_key"]).to be_nil
    end

    it "applies ohai data to the node" do
      expect(node["fqdn"]).to eq(ohai_data["fqdn"])
    end

    it "reports that a temporary_policy is not being used" do
      expect(policy_builder.temporary_policy?).to be_falsey
    end

    describe "when the given run list is not in expanded form" do

      # NOTE: for chef-client, the behavior is always to expand the run list,
      # but this operation is a no-op when none of the run list items are
      # roles. Because of the amount of mocking required to make this work in
      # tests, this test is isolated from the others.

      let(:primary_runlist) { ["role[some_role]"] }
      let(:expansion) do
        recipe_list = Chef::RunList::VersionedRecipeList.new
        recipe_list.add_recipe("recipe[from_role::default", "1.0.2")
        double("RunListExpansion", :recipes => recipe_list)
      end

      let(:node) do
        node = Chef::Node.new
        node.name(node_name)
        node.default_attrs = original_default_attrs
        node.override_attrs = original_override_attrs
        node.run_list(primary_runlist)

        expect(node).to receive(:expand!).with("server") do
          node.run_list("recipe[from_role::default]")
          expansion
        end

        node
      end

      it "expands run list items via the server API" do
        expect(node.run_list).to eq(["recipe[from_role::default]"])
      end

    end

    context "when JSON attributes are given on the command line" do

      let(:json_attribs) { { "run_list" => ["recipe[json_attribs::default]"], "json_attribs_key" => "json_attribs_value" } }

      it "sets the run list according to the given JSON" do
        expect(node.run_list).to eq(["recipe[json_attribs::default]"])
      end

      it "sets node attributes according to the given JSON" do
        expect(node["json_attribs_key"]).to eq("json_attribs_value")
      end

    end

    context "when an override_runlist is given" do

      let(:override_runlist) { "recipe[foo::default]" }

      it "sets the override run_list on the node" do
        expect(node.run_list).to eq([override_runlist])
        expect(node.primary_runlist).to eq(primary_runlist)
      end

      it "reports that a temporary policy is being used" do
        expect(policy_builder.temporary_policy?).to be_truthy
      end

    end

    context "when no environment is specified" do

      it "does not set the environment" do
        expect(node.chef_environment).to eq("_default")
      end

    end

    context "when a custom environment is configured" do

      let(:configured_environment) { environment.name }

      let(:environment) do
        environment = Chef::Environment.new.tap { |e| e.name("prod") }
        expect(Chef::Environment).to receive(:load).with("prod").and_return(environment)
        environment
      end

      it "sets the environment as configured" do
        expect(node.chef_environment).to eq(environment.name)
      end
    end

  end

  describe "configuring the run_context" do
    let(:json_attribs) { nil }
    let(:override_runlist) { nil }

    let(:node) do
      node = Chef::Node.new
      node.name(node_name)
      node.run_list("recipe[first::default]", "recipe[second::default]")
      node
    end

    let(:chef_http) { double("Chef::ServerAPI") }

    let(:cookbook_resolve_url) { "environments/#{node.chef_environment}/cookbook_versions" }
    let(:cookbook_resolve_post_data) { { :run_list => ["first::default", "second::default"] } }

    # cookbook_hash is just a hash, but since we're passing it between mock
    # objects, we get a little better test strictness by using a double (which
    # will have object equality rather than semantic equality #== semantics).
    let(:cookbook_hash) { double("cookbook hash") }
    let(:expanded_cookbook_hash) { double("expanded cookbook hash", :each => nil) }

    let(:cookbook_synchronizer) { double("CookbookSynchronizer") }

    before do
      allow(policy_builder).to receive(:api_service).and_return(chef_http)

      policy_builder.finish_load_node(node)
      policy_builder.build_node

      run_list_expansion = policy_builder.run_list_expansion

      expect(cookbook_hash).to receive(:inject).and_return(expanded_cookbook_hash)
      expect(chef_http).to receive(:post).with(cookbook_resolve_url, cookbook_resolve_post_data).and_return(cookbook_hash)
      expect(Chef::CookbookSynchronizer).to receive(:new).with(expanded_cookbook_hash, events).and_return(cookbook_synchronizer)
      expect(cookbook_synchronizer).to receive(:sync_cookbooks)

      expect_any_instance_of(Chef::RunContext).to receive(:load).with(run_list_expansion)

      policy_builder.setup_run_context
    end

    it "configures FileVendor to fetch files remotely" do
      manifest = double("cookbook manifest")
      expect(Chef::Cookbook::RemoteFileVendor).to receive(:new).with(manifest, chef_http)
      Chef::Cookbook::FileVendor.create_from_manifest(manifest)
    end

    it "triggers cookbook compilation in the run_context" do
      # Test condition already covered by `Chef::RunContext.any_instance.should_receive(:load).with(run_list_expansion)`
    end

  end

end
