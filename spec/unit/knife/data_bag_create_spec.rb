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

  let(:secret) { "abc123SECRET" }
  let(:secret_file) do
    sfile = Tempfile.new("encrypted_data_bag_secret")
    sfile.puts(secret)
    sfile.flush
  end

  let(:raw_hash)  {{ "login_name" => "alphaomega", "id" => item_name }}

  let(:config) { {} }

  before do
    Chef::Config[:node_name] = "webmonkey.example.com"
    knife.name_args = [bag_name, item_name]
    allow(knife).to receive(:config).and_return(config)
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

  shared_examples_for "an encrypted data bag item" do
    let(:encoded_data) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(raw_hash, secret) }

    let(:item) do
      item = Chef::DataBagItem.from_hash(encoded_data)
      item.data_bag(bag_name)
      item
    end

    it "creates an encrypted data bag item" do
      expect(knife).to receive(:create_object).and_yield(raw_hash)
      expect(Chef::EncryptedDataBagItem)
        .to receive(:encrypt_data_bag_item)
        .with(raw_hash, secret)
        .and_return(encoded_data)
      expect(rest).to receive(:post_rest).with("data", {"name" => bag_name}).ordered
      expect(rest).to receive(:post_rest).with("data/#{bag_name}", item).ordered

      knife.run
    end
  end

  context "when given two arguments" do
    include_examples "a data bag item"
  end

  context "when provided --secret and --secret-file" do

    let(:config) {{ :secret_file => secret_file.path, :secret => secret }}

    it "throws an error" do
      expect(knife).to receive(:create_object).and_yield(raw_hash)
      expect(knife).to receive(:exit).with(1)
      expect(knife.ui).to receive(:fatal).with("Please specify only one of --secret, --secret-file")

      knife.run
    end

  end

  context "when provided with `secret` and `secret_file` in knife.rb" do
    before do
      Chef::Config[:knife][:secret] = secret
      Chef::Config[:knife][:secret_file] = secret_file.path
    end

    it "throws an error" do
      expect(knife).to receive(:create_object).and_yield(raw_hash)
      expect(knife).to receive(:exit).with(1)
      expect(knife.ui).to receive(:fatal).with("Please specify only one of 'secret' or 'secret_file' in your config")

      knife.run
    end

  end

  context "when --encrypt is provided without a secret" do
    let(:config) {{ :encrypt => true }}

    it "throws an error" do
      expect(knife).to receive(:create_object).and_yield(raw_hash)
      expect(knife).to receive(:exit).with(1)
      expect(knife.ui).to receive(:fatal).with("No secret or secret_file specified in config, unable to encrypt item.")

      knife.run
    end
  end

  context "with secret in knife.rb" do
    before do
      Chef::Config[:knife][:secret] = config_secret
    end

    include_examples "a data bag item" do
      let(:config_secret) { secret }
    end

    context "with --encrypt" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :encrypt => true }}
        let(:config_secret) { secret }
      end
    end

    context "with --secret" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :secret => secret }}
        let(:config_secret) { "TERCES321cba" }
      end
    end

    context "with --secret-file" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :secret_file => secret_file.path }}
        let(:config_secret) { "TERCES321cba" }
      end
    end
  end

  context "with secret_file in knife.rb" do
    before do
      Chef::Config[:knife][:secret_file] = config_secret_file
    end

    include_examples "a data bag item" do
      let(:config_secret_file) { secret_file.path }
    end

    context "with --encrypt" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :encrypt => true }}
        let(:config_secret_file) { secret_file.path }
      end
    end

    context "with --secret" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :secret => secret }}
        let(:config_secret_file) { "/etc/chef/encrypted_data_bag_secret" }
      end
    end

    context "with --secret-file" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :secret_file => secret_file.path }}
        let(:config_secret_file) { "/etc/chef/encrypted_data_bag_secret" }
      end
    end
  end

  context "no secret in knife.rb" do

    include_examples "a data bag item"

    context "with --secret" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :secret => secret }}
      end
    end

    context "with --secret-file" do
      include_examples "an encrypted data bag item" do
        let(:config) {{ :secret_file => secret_file.path }}
      end
    end
  end
end
