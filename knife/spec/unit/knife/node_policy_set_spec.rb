#
# Author:: Piyush Awasthi (<piyush.awasthi@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the License);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an AS IS BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "knife_spec_helper"

describe Chef::Knife::NodePolicySet do
  let(:node) do
    node = Chef::Node.new
    node.name("adam")
    node.run_list = ["role[base]"]
    node
  end

  let(:knife) do
    Chef::Log.logger = Logger.new(StringIO.new)
    Chef::Config[:knife][:bootstrap_template] = bootstrap_template unless bootstrap_template.nil?
    knife_obj = Chef::Knife::NodePolicySet.new(bootstrap_cli_options)
    knife_obj.merge_configs
    allow(knife_obj.ui).to receive(:stderr).and_return(stderr)
    allow(knife_obj).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(false)
    knife_obj
  end

  let(:stderr) { StringIO.new }
  let(:bootstrap_template) { nil }
  let(:bootstrap_cli_options) { [ ] }

  describe "#run" do
    context "when node_name is not given" do
      let(:bootstrap_cli_options) { %w{ } }
      it "returns an error that you must specify a node name" do
        expect { knife.send(:validate_node!) }.to raise_error(SystemExit)
        expect(stderr.string).to include("ERROR: You must specify a node name")
      end
    end

    context "when node is given" do
      let(:bootstrap_cli_options) { %w{ adam staging my-app } }
      it "should load the node" do
        expect(Chef::Node).to receive(:load).with(bootstrap_cli_options[0]).and_return(node)
        allow(node).to receive(:save).and_return(true)
        knife.run
      end
    end

    context "when node not saved" do
      let(:bootstrap_cli_options) { %w{ adam staging my-app } }
      it "returns an error node not updated successfully" do
        allow(Chef::Node).to receive(:load).with(bootstrap_cli_options[0]).and_return(node)
        allow(node).to receive(:save).and_return(false)
        knife.run
        expect(stderr.string.strip).to eq("Error in updating node #{node.name}")
      end
    end

    context "when the policy is set successfully on the node" do
      let(:bootstrap_cli_options) { %w{ adam staging my-app } }
      it "returns node updated successfully" do
        allow(Chef::Node).to receive(:load).with(bootstrap_cli_options[0]).and_return(node)
        allow(node).to receive(:save).and_return(true)
        knife.run
        expect(stderr.string.strip).to eq("Successfully set the policy on node #{node.name}")
      end
    end
  end

  describe "handling policy options" do
    context "when policy_group and policy_name is not given" do
      let(:bootstrap_cli_options) { %w{ } }
      it "returns an error stating that policy_name and policy_group must be given together" do
        expect { knife.send(:validate_options!) }.to raise_error(SystemExit)
        expect(stderr.string).to include("ERROR: Policy group and name must be specified together")
      end
    end

    context "when only policy_name is given" do
      let(:bootstrap_cli_options) { %w{ adam staging } }
      it "returns an error stating that policy_name and policy_group must be given together" do
        expect { knife.send(:validate_options!) }.to raise_error(SystemExit)
        expect(stderr.string).to include("ERROR: Policy group and name must be specified together")
      end
    end

    context "when only policy_group is given" do
      let(:bootstrap_cli_options) { %w{ adam my-app } }
      it "returns an error stating that policy_name and policy_group must be given together" do
        expect { knife.send(:validate_options!) }.to raise_error(SystemExit)
        expect(stderr.string).to include("ERROR: Policy group and name must be specified together")
      end
    end

    context "when policy_name and policy_group are given with no conflicting options" do
      let(:bootstrap_cli_options) { %w{ adam staging my-app } }
      it "passes options validation" do
        expect { knife.send(:validate_options!) }.to_not raise_error
      end

      it "returns value set in config" do
        allow(Chef::Node).to receive(:load).with(bootstrap_cli_options[0]).and_return(node)
        allow(node).to receive(:save).and_return(false)
        knife.run
        expect(node.policy_name).to eq("my-app")
        expect(node.policy_group).to eq("staging")
      end
    end
  end
end
