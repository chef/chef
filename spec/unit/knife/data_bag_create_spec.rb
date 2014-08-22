#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2009-2010 Opscode, Inc.
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
require 'tempfile'

module ChefSpecs
  class ChefRest
    attr_reader :args_received
    def initialize
      @args_received = []
    end

    def post_rest(*args)
      @args_received << args
    end
  end
end

describe Chef::Knife::DataBagCreate do
  let(:knife) do
    k = Chef::Knife::DataBagCreate.new
    allow(k).to receive(:rest).and_return(rest)
    allow(k.ui).to receive(:stdout).and_return(stdout)
    k
  end

  let(:rest) { ChefSpecs::ChefRest.new }
  let(:stdout) { StringIO.new }

  let(:bag_name) { "sudoing_admins" }
  let(:item_name) { "ME" }

  before do
    Chef::Config[:node_name] = "webmonkey.example.com"
  end

  it "tries to create a data bag with an invalid name when given one argument" do
    knife.name_args = ['invalid&char']
    expect(knife).to receive(:exit).with(1)
    knife.run
  end

  context "when given one argument" do
    before do
      knife.name_args = [bag_name]
    end

    it "creates a data bag" do
      expect(rest).to receive(:post_rest).with("data", {"name" => bag_name})
      expect(knife.ui).to receive(:info).with("Created data_bag[#{bag_name}]")

      knife.run
    end
  end

  shared_examples_for "a data bag item" do
    let(:item) do
      item = Chef::DataBagItem.from_hash(raw_hash)
      item.data_bag(bag_name)
      item
    end

    let(:raw_hash)  {{ "login_name" => "alphaomega", "id" => item_name }}

    before do
      knife.name_args = [bag_name, item_name]
    end

    it "creates a data bag item" do
      expect(knife).to receive(:create_object).and_yield(raw_hash)
      expect(rest).to receive(:post_rest).with("data", {'name' => bag_name}).ordered
      expect(rest).to receive(:post_rest).with("data/#{bag_name}", item).ordered

      knife.run
    end
  end

  context "when given two arguments" do
    include_examples "a data bag item"
  end

  describe "encrypted data bag items" do
    let(:secret) { "abc123SECRET" }
    let(:secret_file) do
      sfile = Tempfile.new("encrypted_data_bag_secret")
      sfile.puts(secret)
      sfile.flush
    end


    let(:raw_data) {{ "login_name" => "alphaomega", "id" => item_name }}
    let(:encoded_data) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(raw_data, secret) }

    let(:item) do
      item = Chef::DataBagItem.from_hash(encoded_data)
      item.data_bag(bag_name)
      item
    end

    before do
      knife.name_args = [bag_name, item_name]
      allow(knife).to receive(:config).and_return(config)
    end

    shared_examples_for "an encrypted data bag item" do
      it "creates an encrypted data bag item" do
        expect(knife).to receive(:create_object).and_yield(raw_data)
        expect(Chef::EncryptedDataBagItem)
          .to receive(:encrypt_data_bag_item)
          .with(raw_data, secret)
          .and_return(encoded_data)
        expect(rest).to receive(:post_rest).with("data", {"name" => bag_name}).ordered
        expect(rest).to receive(:post_rest).with("data/#{bag_name}", item).ordered

        knife.run
      end
    end

    context "via --secret" do
      include_examples "an encrypted data bag item" do
        let(:config) { {:secret => secret} }
      end
    end

    context "via --secret-file" do
      include_examples "an encrypted data bag item" do
        let(:config) { {:secret_file => secret_file} }
      end
    end

    context "via --secret and --secret-file" do
      let(:config) { {:secret => secret, :secret_file => secret_file} }

      it "fails to create an encrypted data bag item" do
        expect(knife).to receive(:create_object).and_yield(raw_data)
        expect(knife).to receive(:exit).with(1)
        knife.run
      end
    end
  end
end
