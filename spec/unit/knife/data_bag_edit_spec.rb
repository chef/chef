#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2010 Opscode, Inc.
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

describe Chef::Knife::DataBagEdit do
  before do
    Chef::Config[:node_name] = "webmonkey.example.com"
    knife.name_args = [bag_name, item_name]
    allow(knife).to receive(:config).and_return(config)
  end

  let(:knife) do
    k = Chef::Knife::DataBagEdit.new
    allow(k).to receive(:rest).and_return(rest)
    allow(k).to receive(:stdout).and_return(stdout)
    k
  end

  let(:plain_hash) { {"login_name" => "alphaomega", "id" => "item_name"} }
  let(:plain_db) {Chef::DataBagItem.from_hash(plain_hash)}
  let(:edited_hash) { {"login_name" => "rho", "id" => "item_name", "new_key" => "new_value"} }
  let(:edited_db) {Chef::DataBagItem.from_hash(edited_hash)}

  let(:rest) { double("ChefSpecs::ChefRest") }
  let(:stdout) { StringIO.new }

  let(:bag_name) { "sudoing_admins" }
  let(:item_name) { "ME" }

  let(:secret) { "abc123SECRET" }

  let(:raw_hash)  {{ "login_name" => "alphaomega", "id" => item_name }}

  let(:config) { {} }

  it "requires data bag and item arguments" do
    knife.name_args = []
    expect(stdout).to receive(:puts).twice.with(anything)
    expect {knife.run}.to exit_with_code(1)
  end

  it "saves edits on a data bag item" do
    expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(plain_db)
    expect(knife).to receive(:encrypted?) { false }
    expect(knife).to receive(:edit_data).with(plain_db).and_return(edited_db.raw_data)
    expect(rest).to receive(:put_rest).with("data/#{bag_name}/#{item_name}", edited_db.raw_data).ordered
    knife.run
  end

  describe "encrypted data bag items" do
    let(:enc_plain_hash) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(plain_hash, secret) }
    let(:data_bag_with_encoded_hash) { Chef::DataBagItem.from_hash(enc_plain_hash) }
    let(:enc_edited_hash) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(edited_hash, secret) }

    before(:each) do
      allow(knife).to receive(:encrypted?) { true }
      allow(knife).to receive(:encryption_secret_provided?) { true }
      allow(knife).to receive(:read_secret).and_return(secret)
    end

    it "decrypts an encrypted data bag, edits it and rencrypts it" do
      expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(data_bag_with_encoded_hash)
      expect(knife).to receive(:edit_data).with(plain_hash).and_return(edited_hash)
      expect(Chef::EncryptedDataBagItem).to receive(:encrypt_data_bag_item).with(edited_hash, secret).and_return(enc_edited_hash)
      expect(rest).to receive(:put_rest).with("data/#{bag_name}/#{item_name}", enc_edited_hash).ordered

      knife.run
    end

    it "edits an unencrypted data bag and encrypts it" do
      expect(knife).to receive(:encrypted?) { false }
      expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(plain_db)
      expect(knife).to receive(:edit_data).with(plain_db).and_return(edited_hash)
      expect(Chef::EncryptedDataBagItem).to receive(:encrypt_data_bag_item).with(edited_hash, secret).and_return(enc_edited_hash)
      expect(rest).to receive(:put_rest).with("data/#{bag_name}/#{item_name}", enc_edited_hash).ordered

      knife.run
    end

    it "fails to edit an encrypted data bag if the secret is missing" do
      allow(knife).to receive(:encryption_secret_provided?) { false }
      expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(data_bag_with_encoded_hash)

      expect(knife.ui).to receive(:fatal).with("You cannot edit an encrypted data bag without providing the secret.")
      expect {knife.run}.to exit_with_code(1)
    end

  end
end
