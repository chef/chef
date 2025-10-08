#
# Author:: Seth Falcon (<seth@chef.io>)
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

require "knife_spec_helper"
require "tempfile"

describe Chef::Knife::DataBagEdit do
  before do
    Chef::Config[:node_name] = "webmonkey.example.com"
    knife.name_args = [bag_name, item_name]
    allow(knife).to receive(:config).and_return(config)
  end

  let(:knife) do
    k = Chef::Knife::DataBagEdit.new
    allow(k).to receive(:rest).and_return(rest)
    allow(k.ui).to receive(:stdout).and_return(stdout)
    k
  end

  let(:raw_hash) { { "login_name" => "alphaomega", "id" => "item_name" } }
  let(:db) { Chef::DataBagItem.from_hash(raw_hash) }
  let(:raw_edited_hash) { { "login_name" => "rho", "id" => "item_name", "new_key" => "new_value" } }

  let(:rest) { double("Chef::ServerAPI") }
  let(:stdout) { StringIO.new }

  let(:bag_name) { "sudoing_admins" }
  let(:item_name) { "ME" }

  let(:secret) { "abc123SECRET" }

  let(:config) { {} }

  let(:is_encrypted?) { false }
  let(:transmitted_hash) { raw_edited_hash }
  let(:data_to_edit) { db.raw_data }
  shared_examples_for "editing a data bag" do
    it "correctly edits then uploads the data bag" do
      expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(db)
      expect(knife).to receive(:encrypted?).with(db.raw_data).and_return(is_encrypted?)
      expect(knife).to receive(:edit_hash).with(data_to_edit).and_return(raw_edited_hash)
      expect(rest).to receive(:put).with("data/#{bag_name}/#{item_name}", transmitted_hash).ordered

      knife.run
    end
  end

  it "requires data bag and item arguments" do
    knife.name_args = []
    expect(stdout).to receive(:puts).twice.with(anything)
    expect { knife.run }.to exit_with_code(1)
    expect(stdout.string).to eq("")
  end

  context "when no secret is provided" do
    include_examples "editing a data bag"
  end

  context "when config[:print_after] is set" do
    let(:config) { { print_after: true } }
    before do
      expect(knife.ui).to receive(:output).with(raw_edited_hash)
    end

    include_examples "editing a data bag"
  end

  context "when a secret is provided" do
    let!(:enc_raw_hash) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(raw_hash, secret) }
    let!(:enc_edited_hash) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(raw_edited_hash, secret) }
    let(:transmitted_hash) { enc_edited_hash }

    before(:each) do
      expect(knife).to receive(:read_secret).at_least(1).times.and_return(secret)
      expect(Chef::EncryptedDataBagItem).to receive(:encrypt_data_bag_item).with(raw_edited_hash, secret).and_return(enc_edited_hash)
    end

    context "the data bag starts encrypted" do
      let(:is_encrypted?) { true }
      let(:db) { Chef::DataBagItem.from_hash(enc_raw_hash) }
      # If the data bag is encrypted, it gets passed to `edit` as a hash.  Otherwise, it gets passed as a DataBag
      let(:data_to_edit) { raw_hash }

      before(:each) do
        expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(true)
      end

      include_examples "editing a data bag"
    end

    context "the data bag starts unencrypted" do
      before(:each) do
        expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).exactly(0).times
        expect(knife).to receive(:encryption_secret_provided?).and_return(true)
      end

      include_examples "editing a data bag"
    end
  end

  it "fails to edit an encrypted data bag if the secret is missing" do
    expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(db)
    expect(knife).to receive(:encrypted?).with(db.raw_data).and_return(true)
    expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(false)

    expect(knife.ui).to receive(:fatal).with("You cannot edit an encrypted data bag without providing the secret.")
    expect { knife.run }.to exit_with_code(1)
  end

end
