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

describe Chef::Knife::DataBagCreate do
  let(:knife) do
    k = Chef::Knife::DataBagCreate.new
    allow(k).to receive(:rest).and_return(rest)
    allow(k.ui).to receive(:stdout).and_return(stdout)
    k
  end

  let(:rest) { double("Chef::REST") }
  let(:stdout) { StringIO.new }

  let(:bag_name) { "sudoing_admins" }
  let(:item_name) { "ME" }

  let(:secret) { "abc123SECRET" }

  let(:raw_hash)  {{ "login_name" => "alphaomega", "id" => item_name }}

  let(:config) { {} }

  before do
    Chef::Config[:node_name] = "webmonkey.example.com"
    knife.name_args = [bag_name, item_name]
    allow(knife).to receive(:config).and_return(config)
  end

  it "tries to create a data bag with an invalid name when given one argument" do
    knife.name_args = ['invalid&char']
    expect(Chef::DataBag).to receive(:validate_name!).with(knife.name_args[0]).and_raise(Chef::Exceptions::InvalidDataBagName)
    expect {knife.run}.to exit_with_code(1)
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

  context "no secret is specified for encryption" do
    let(:item) do
      item = Chef::DataBagItem.from_hash(raw_hash)
      item.data_bag(bag_name)
      item
    end

    it "creates a data bag item" do
      expect(knife).to receive(:create_object).and_yield(raw_hash)
      expect(knife).to receive(:encryption_secret_provided?).and_return(false)
      expect(rest).to receive(:post_rest).with("data", {'name' => bag_name}).ordered
      expect(rest).to receive(:post_rest).with("data/#{bag_name}", item).ordered

      knife.run
    end
  end

  context "a secret is specified for encryption" do
    let(:encoded_data) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(raw_hash, secret) }

    let(:item) do
      item = Chef::DataBagItem.from_hash(encoded_data)
      item.data_bag(bag_name)
      item
    end

    it "creates an encrypted data bag item" do
      expect(knife).to receive(:create_object).and_yield(raw_hash)
      expect(knife).to receive(:encryption_secret_provided?).and_return(true)
      expect(knife).to receive(:read_secret).and_return(secret)
      expect(Chef::EncryptedDataBagItem)
        .to receive(:encrypt_data_bag_item)
        .with(raw_hash, secret)
        .and_return(encoded_data)
      expect(rest).to receive(:post_rest).with("data", {"name" => bag_name}).ordered
      expect(rest).to receive(:post_rest).with("data/#{bag_name}", item).ordered

      knife.run
    end
  end

end
