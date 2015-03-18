#
# Author:: Lamont Granquist <lamont@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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


describe Chef::Knife::Bootstrap::ClientBuilder do

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin) { StringIO.new }
  let(:ui) { Chef::Knife::UI.new(stdout, stderr, stdin, {}) }

  let(:knife_config) { {} }

  let(:chef_config) { {} }

  let(:node_name) { "bevell.wat" }

  let(:rest) { double("Chef::REST") }

  let(:client_builder) {
    client_builder = Chef::Knife::Bootstrap::ClientBuilder.new(knife_config: knife_config, chef_config: chef_config, ui: ui)
    allow(client_builder).to receive(:rest).and_return(rest)
    allow(client_builder).to receive(:node_name).and_return(node_name)
    client_builder
  }

  context "#sanity_check!" do
    let(:response_404) { OpenStruct.new(:code => '404') }
    let(:exception_404) { Net::HTTPServerException.new("404 not found", response_404) }

    context "in cases where the prompting fails" do
      before do
        # should fail early in #run
        expect(client_builder).to_not receive(:create_client!)
        expect(client_builder).to_not receive(:create_node!)
      end

      it "exits when the node exists and the user does not want to delete" do
        expect(rest).to receive(:get_rest).with("nodes/#{node_name}")
        expect(ui.stdin).to receive(:readline).and_return('n')
        expect { client_builder.run }.to raise_error(SystemExit)
      end

      it "exits when the client exists and the user does not want to delete" do
        expect(rest).to receive(:get_rest).with("nodes/#{node_name}").and_raise(exception_404)
        expect(rest).to receive(:get_rest).with("clients/#{node_name}")
        expect(ui.stdin).to receive(:readline).and_return('n')
        expect { client_builder.run }.to raise_error(SystemExit)
      end
    end

    context "in cases where the prompting succeeds" do
      before do
        # mock out the rest of #run
        expect(client_builder).to receive(:create_client!)
        expect(client_builder).to receive(:create_node!)
      end

      it "when both the client and node do not exist it succeeds" do
        expect(rest).to receive(:get_rest).with("nodes/#{node_name}").and_raise(exception_404)
        expect(rest).to receive(:get_rest).with("clients/#{node_name}").and_raise(exception_404)
        expect { client_builder.run }.not_to raise_error
      end

      it "when we are allowed to delete an old node" do
        expect(rest).to receive(:get_rest).with("nodes/#{node_name}")
        expect(ui.stdin).to receive(:readline).and_return('y')
        expect(rest).to receive(:get_rest).with("clients/#{node_name}").and_raise(exception_404)
        expect(rest).to receive(:delete).with("nodes/#{node_name}")
        expect { client_builder.run }.not_to raise_error
      end

      it "when we are allowed to delete an old client" do
        expect(rest).to receive(:get_rest).with("nodes/#{node_name}").and_raise(exception_404)
        expect(rest).to receive(:get_rest).with("clients/#{node_name}")
        expect(ui.stdin).to receive(:readline).and_return('y')
        expect(rest).to receive(:delete).with("clients/#{node_name}")
        expect { client_builder.run }.not_to raise_error
      end

      it "when we are are allowed to delete both an old client and node" do
        expect(rest).to receive(:get_rest).with("nodes/#{node_name}")
        expect(rest).to receive(:get_rest).with("clients/#{node_name}")
        expect(ui.stdin).to receive(:readline).twice.and_return('y')
        expect(rest).to receive(:delete).with("nodes/#{node_name}")
        expect(rest).to receive(:delete).with("clients/#{node_name}")
        expect { client_builder.run }.not_to raise_error
      end
    end
  end

  context "#create_client!" do
    before do
      # mock out the rest of #run
      expect(client_builder).to receive(:sanity_check)
      expect(client_builder).to receive(:create_node!)
    end

    it "delegates everything to Chef::ApiClient::Registration" do
      reg_double = double("Chef::ApiClient::Registration")
      expect(Chef::ApiClient::Registration).to receive(:new).with(node_name, client_builder.client_path, http_api: rest).and_return(reg_double)
      expect(reg_double).to receive(:run)
      client_builder.run
    end

  end

  context "#client_path" do
    it "has a public API for the temporary client.pem file" do
      expect(client_builder.client_path).to match(/#{node_name}.pem/)
    end
  end

  context "#create_node!" do
    before do
      # mock out the rest of #run
      expect(client_builder).to receive(:sanity_check)
      expect(client_builder).to receive(:create_client!)
      # mock out default node building steps
      expect(client_builder).to receive(:client_rest).and_return(client_rest)
      expect(Chef::Node).to receive(:new).with(chef_server_rest: client_rest).and_return(node)
      expect(node).to receive(:name).with(node_name)
      expect(node).to receive(:save)
    end

    let(:client_rest) { double("Chef::REST (client)") }

    let(:node) { double("Chef::Node") }

    it "builds a node with a default run_list of []" do
      expect(node).to receive(:run_list).with([])
      client_builder.run
    end

    it "builds a node when the run_list is a string" do
      knife_config[:run_list] = "role[base],role[app]"
      expect(node).to receive(:run_list).with(["role[base]", "role[app]"])
      client_builder.run
    end

    it "builds a node when the run_list is an Array" do
      knife_config[:run_list] = ["role[base]", "role[app]"]
      expect(node).to receive(:run_list).with(["role[base]", "role[app]"])
      client_builder.run
    end

    it "builds a node with first_boot_attributes if they're given" do
      knife_config[:first_boot_attributes] = {:baz => :quux}
      expect(node).to receive(:normal_attrs=).with({:baz=>:quux})
      expect(node).to receive(:run_list).with([])
      client_builder.run
    end

    it "builds a node with an environment if its given" do
      knife_config[:environment] = "production"
      expect(node).to receive(:environment).with("production")
      expect(node).to receive(:run_list).with([])
      client_builder.run
    end
  end
end
