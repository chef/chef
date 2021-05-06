#
# Author:: Adam Jacob (<adam@chef.io>)
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

require "chef/data_bag_item"
require "chef/encrypted_data_bag_item"
require "chef/json_compat"
require "tempfile"

describe Chef::Knife::DataBagShow do

  before do
    Chef::Config[:node_name] = "webmonkey.example.com"
    knife.name_args = [bag_name, item_name]
    allow(knife).to receive(:config).and_return(config)
  end

  let(:knife) do
    k = Chef::Knife::DataBagShow.new
    allow(k).to receive(:rest).and_return(rest)
    allow(k.ui).to receive(:stdout).and_return(stdout)
    k
  end

  let(:rest) { double("Chef::ServerAPI") }
  let(:stdout) { StringIO.new }

  let(:bag_name) { "sudoing_admins" }
  let(:item_name) { "ME" }

  let(:data_bag_contents) do
    { "id" => "id", "baz" => "http://localhost:4000/data/bag_o_data/baz",
      "qux" => "http://localhost:4000/data/bag_o_data/qux" }
  end
  let(:enc_hash) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(data_bag_contents, secret) }
  let(:data_bag) { Chef::DataBagItem.from_hash(data_bag_contents) }
  let(:data_bag_with_encoded_hash) { Chef::DataBagItem.from_hash(enc_hash) }
  let(:enc_data_bag) { Chef::EncryptedDataBagItem.new(enc_hash, secret) }

  let(:secret) { "abc123SECRET" }
  #
  # let(:raw_hash)  {{ "login_name" => "alphaomega", "id" => item_name }}
  #
  let(:config) { { format: "json" } }

  context "Data bag to show is encrypted" do
    before do
      allow(knife).to receive(:encrypted?).and_return(true)
    end

    it "decrypts and displays the encrypted data bag when the secret is provided" do
      expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(true)
      expect(knife).to receive(:read_secret).and_return(secret)
      expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(data_bag_with_encoded_hash)
      expect(knife.ui).to receive(:info).with("Encrypted data bag detected, decrypting with provided secret.")
      expect(Chef::EncryptedDataBagItem).to receive(:load).with(bag_name, item_name, secret).and_return(enc_data_bag)

      expected = %q{baz: http://localhost:4000/data/bag_o_data/baz
id:  id
qux: http://localhost:4000/data/bag_o_data/qux}
      knife.run
      expect(stdout.string.strip).to eq(expected)
    end

    it "displays the encrypted data bag when the secret is not provided" do
      expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(false)
      expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(data_bag_with_encoded_hash)
      expect(knife.ui).to receive(:warn).with("Encrypted data bag detected, but no secret provided for decoding. Displaying encrypted data.")

      knife.run
      expect(stdout.string.strip).to include("baz", "qux", "cipher")
    end
  end

  context "Data bag to show is not encrypted" do
    before do
      allow(knife).to receive(:encrypted?).and_return(false)
    end

    it "displays the data bag" do
      expect(knife).to receive(:read_secret).exactly(0).times
      expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(data_bag)

      expected = %q{baz: http://localhost:4000/data/bag_o_data/baz
id:  id
qux: http://localhost:4000/data/bag_o_data/qux}
      knife.run
      expect(stdout.string.strip).to eq(expected)
    end

    context "when a secret is given" do
      it "displays the data bag" do
        expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(true)
        expect(knife).to receive(:read_secret).and_return(secret)
        expect(Chef::DataBagItem).to receive(:load).with(bag_name, item_name).and_return(data_bag)
        expect(knife.ui).to receive(:warn).with("Unencrypted data bag detected, ignoring any provided secret options.")

        expected = %q{baz: http://localhost:4000/data/bag_o_data/baz
id:  id
qux: http://localhost:4000/data/bag_o_data/qux}
        knife.run
        expect(stdout.string.strip).to eq(expected)
      end
    end
  end

  it "displays the list of items in the data bag when only one @name_arg is provided" do
    knife.name_args = [bag_name]
    expect(Chef::DataBag).to receive(:load).with(bag_name).and_return({})

    knife.run
    expect(stdout.string.strip).to eq("")
  end

  it "raises an error when no @name_args are provided" do
    knife.name_args = []

    expect { knife.run }.to exit_with_code(1)
    expect(stdout.string).to start_with("knife data bag show BAG [ITEM] (options)")
  end

end
