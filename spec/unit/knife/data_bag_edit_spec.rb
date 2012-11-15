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
    @plain_data = {"login_name" => "alphaomega", "id" => "item_name"}
    @edited_data = {
      "login_name" => "rho", "id" => "item_name",
      "new_key" => "new_value" }

    Chef::Config[:node_name]  = "webmonkey.example.com"

    @knife = Chef::Knife::DataBagEdit.new
    @rest = mock('chef-rest-mock')
    @knife.stub!(:rest).and_return(@rest)

    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @log = Chef::Log
    @knife.name_args = ['bag_name', 'item_name']
  end

  it "requires data bag and item arguments" do
    @knife.name_args = []
    lambda { @knife.run }.should raise_error(SystemExit)
    @stdout.string.should match(/^You must supply the data bag and an item to edit/)
  end

  it "saves edits on a data bag item" do
    Chef::DataBagItem.stub!(:load).with('bag_name', 'item_name').and_return(@plain_data)
    @knife.should_receive(:edit_data).with(@plain_data).and_return(@edited_data)
    @rest.should_receive(:put_rest).with("data/bag_name/item_name", @edited_data).ordered
    @knife.run
  end

  describe "encrypted data bag items" do
    before(:each) do
      @secret = "abc123SECRET"
      @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                   @secret)
      @enc_edited_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@edited_data,
                                                                          @secret)
      Chef::DataBagItem.stub!(:load).with('bag_name', 'item_name').and_return(@enc_data)

      # Random IV is used each time the data bag item is encrypted, so values
      # will not be equal if we encrypt same value twice.
      Chef::EncryptedDataBagItem.should_receive(:encrypt_data_bag_item).and_return(@enc_edited_data)

      @secret_file = Tempfile.new("encrypted_data_bag_secret_file_test")
      @secret_file.puts(@secret)
      @secret_file.flush
    end

    after do
      @secret_file.close
      @secret_file.unlink
    end

    it "decrypts and encrypts via --secret" do
      @knife.stub!(:config).and_return({:secret => @secret})
      @knife.should_receive(:edit_data).with(@plain_data).and_return(@edited_data)
      @rest.should_receive(:put_rest).with("data/bag_name/item_name", @enc_edited_data).ordered

      @knife.run
    end

    it "decrypts and encrypts via --secret_file" do
      @knife.stub!(:config).and_return({:secret_file => @secret_file.path})
      @knife.should_receive(:edit_data).with(@plain_data).and_return(@edited_data)
      @rest.should_receive(:put_rest).with("data/bag_name/item_name", @enc_edited_data).ordered

      @knife.run
    end
  end
end
