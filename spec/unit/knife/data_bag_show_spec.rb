#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2008-2010 Opscode, Inc.
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

require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'chef/json_compat'
require 'tempfile'

describe Chef::Knife::DataBagShow do
  before do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::DataBagShow.new
    @knife.config[:format] = 'json'
    @rest = double("Chef::REST")
    allow(@knife).to receive(:rest).and_return(@rest)
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
  end


  it "prints the ids of the data bag items when given a bag name" do
    @knife.instance_variable_set(:@name_args, ['bag_o_data'])
    data_bag_contents = { "baz"=>"http://localhost:4000/data/bag_o_data/baz",
      "qux"=>"http://localhost:4000/data/bag_o_data/qux"}
    expect(Chef::DataBag).to receive(:load).and_return(data_bag_contents)
    expected = %q|[
  "baz",
  "qux"
]|
    @knife.run
    expect(@stdout.string.strip).to eq(expected)
  end

  it "prints the contents of the data bag item when given a bag and item name" do
    @knife.instance_variable_set(:@name_args, ['bag_o_data', 'an_item'])
    data_item = Chef::DataBagItem.new.tap {|item| item.raw_data = {"id" => "an_item", "zsh" => "victory_through_tabbing"}}

    expect(Chef::DataBagItem).to receive(:load).with('bag_o_data', 'an_item').and_return(data_item)

    @knife.run
    expect(Chef::JSONCompat.from_json(@stdout.string)).to eq(data_item.raw_data)
  end

  it "should pretty print the data bag contents" do
    @knife.instance_variable_set(:@name_args, ['bag_o_data', 'an_item'])
    data_item = Chef::DataBagItem.new.tap {|item| item.raw_data = {"id" => "an_item", "zsh" => "victory_through_tabbing"}}

    expect(Chef::DataBagItem).to receive(:load).with('bag_o_data', 'an_item').and_return(data_item)

    @knife.run
    expect(@stdout.string).to eql("{\n  \"id\": \"an_item\",\n  \"zsh\": \"victory_through_tabbing\"\n}\n")
  end

  describe "encrypted data bag items" do
    before(:each) do
      @secret = "abc123SECRET"
      @plain_data = {
        "id" => "item_name",
        "greeting" => "hello",
        "nested" => { "a1" => [1, 2, 3], "a2" => { "b1" => true }}
      }
      @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                   @secret)
      @knife.instance_variable_set(:@name_args, ['bag_name', 'item_name'])

      @secret_file = Tempfile.new("encrypted_data_bag_secret_file_test")
      @secret_file.puts(@secret)
      @secret_file.flush
    end

    after do
      @secret_file.close
      @secret_file.unlink
    end

    it "prints the decrypted contents of an item when given --secret" do
      allow(@knife).to receive(:config).and_return({:secret => @secret})
      expect(Chef::EncryptedDataBagItem).to receive(:load).
        with('bag_name', 'item_name', @secret).
        and_return(Chef::EncryptedDataBagItem.new(@enc_data, @secret))
      @knife.run
      expect(Chef::JSONCompat.from_json(@stdout.string)).to eq(@plain_data)
    end

    it "prints the decrypted contents of an item when given --secret_file" do
      allow(@knife).to receive(:config).and_return({:secret_file => @secret_file.path})
      expect(Chef::EncryptedDataBagItem).to receive(:load).
        with('bag_name', 'item_name', @secret).
        and_return(Chef::EncryptedDataBagItem.new(@enc_data, @secret))
      @knife.run
      expect(Chef::JSONCompat.from_json(@stdout.string)).to eq(@plain_data)
    end
  end

  describe "command line parsing" do
    it "prints help if given no arguments" do
      @knife.instance_variable_set(:@name_args, [])
      expect { @knife.run }.to raise_error(SystemExit)
      expect(@stdout.string).to match(/^knife data bag show BAG \[ITEM\] \(options\)/)
    end
  end

end
