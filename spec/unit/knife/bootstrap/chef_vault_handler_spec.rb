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

describe Chef::Knife::Bootstrap::ChefVaultHandler do

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin) { StringIO.new }
  let(:ui) { Chef::Knife::UI.new(stdout, stderr, stdin, {}) }

  let(:knife_config) { {} }

  let(:node_name) { "bevell.wat" }

  let(:chef_vault_handler) {
    chef_vault_handler = Chef::Knife::Bootstrap::ChefVaultHandler.new(knife_config: knife_config, ui: ui)
    chef_vault_handler
  }

  context "when there's no vault option" do
    it "should report its not doing anything" do
      expect(chef_vault_handler.doing_chef_vault?).to be false
    end

    it "shouldn't do anything" do
      expect(chef_vault_handler).to_not receive(:sanity_check)
      expect(chef_vault_handler).to_not receive(:update_bootstrap_vault_json!)
      chef_vault_handler
    end
  end

  context "when setting chef vault items" do
    let(:bootstrap_vault_item) { double("ChefVault::Item") }

    before do
      expect(chef_vault_handler).to receive(:wait_for_client).and_return(false)
      expect(chef_vault_handler).to receive(:require_chef_vault!).at_least(:once)
      expect(bootstrap_vault_item).to receive(:clients).with("name:#{node_name}").at_least(:once)
      expect(bootstrap_vault_item).to receive(:save).at_least(:once)
    end

    context "from knife_config[:bootstrap_vault_item]" do
      it "sets a single item as a scalar" do
        knife_config[:bootstrap_vault_item] = { 'vault' => 'item1' }
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets a single item as an array" do
        knife_config[:bootstrap_vault_item] = { 'vault' => [ 'item1' ] }
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets two items as an array" do
        knife_config[:bootstrap_vault_item] = { 'vault' => [ 'item1', 'item2' ] }
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item2').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets two vaults from different hash keys" do
        knife_config[:bootstrap_vault_item] = { 'vault' => [ 'item1', 'item2' ], 'vault2' => [ 'item3' ] }
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item2').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault2', 'item3').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end
    end

    context "from knife_config[:bootstrap_vault_json]" do
      it "sets a single item as a scalar" do
        knife_config[:bootstrap_vault_json] = '{ "vault": "item1" }'
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets a single item as an array" do
        knife_config[:bootstrap_vault_json] = '{ "vault": [ "item1" ] }'
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets two items as an array" do
        knife_config[:bootstrap_vault_json] = '{ "vault": [ "item1", "item2" ] }'
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item2').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets two vaults from different hash keys" do
        knife_config[:bootstrap_vault_json] = '{ "vault": [ "item1", "item2" ], "vault2": [ "item3" ] }'
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item2').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault2', 'item3').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end
    end

    context "from knife_config[:bootstrap_vault_file]" do

      def setup_file_contents(json)
        stringio = StringIO.new(json)
        knife_config[:bootstrap_vault_file] = "/foo/bar/baz"
        expect(File).to receive(:read).with(knife_config[:bootstrap_vault_file]).and_return(stringio)
      end

      it "sets a single item as a scalar" do
        setup_file_contents('{ "vault": "item1" }')
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets a single item as an array" do
        setup_file_contents('{ "vault": [ "item1" ] }')
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets two items as an array" do
        setup_file_contents('{ "vault": [ "item1", "item2" ] }')
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item2').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end

      it "sets two vaults from different hash keys" do
        setup_file_contents('{ "vault": [ "item1", "item2" ], "vault2": [ "item3" ] }')
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item1').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault', 'item2').and_return(bootstrap_vault_item)
        expect(chef_vault_handler).to receive(:load_chef_bootstrap_vault_item).with('vault2', 'item3').and_return(bootstrap_vault_item)
        chef_vault_handler.run(node_name: node_name)
      end
    end
  end
end
