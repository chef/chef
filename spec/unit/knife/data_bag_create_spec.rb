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
  before do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::DataBagCreate.new
    @rest = ChefSpecs::ChefRest.new
    @knife.stub!(:rest).and_return(@rest)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end


  it "creates a data bag when given one argument" do
    @knife.name_args = ['sudoing_admins']
    @rest.should_receive(:post_rest).with("data", {"name" => "sudoing_admins"})
    @knife.ui.should_receive(:info).with("Created data_bag[sudoing_admins]")

    @knife.run
  end

  it "creates a data bag item when given two arguments" do
    @knife.name_args = ['sudoing_admins', 'ME']
    user_supplied_hash = {"login_name" => "alphaomega", "id" => "ME"}
    data_bag_item = Chef::DataBagItem.from_hash(user_supplied_hash)
    data_bag_item.data_bag("sudoing_admins")
    @knife.should_receive(:create_object).and_yield(user_supplied_hash)
    @rest.should_receive(:post_rest).with("data", {'name' => 'sudoing_admins'}).ordered
    @rest.should_receive(:post_rest).with("data/sudoing_admins", data_bag_item).ordered

    @knife.run
  end

  describe "encrypted data bag items" do
    before(:each) do
      @secret = "abc123SECRET"
      @plain_data = {"login_name" => "alphaomega", "id" => "ME"}
      @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                   @secret)
      @knife.name_args = ['sudoing_admins', 'ME']
      @knife.should_receive(:create_object).and_yield(@plain_data)
      data_bag_item = Chef::DataBagItem.from_hash(@enc_data)
      data_bag_item.data_bag("sudoing_admins")

      # Random IV is used each time the data bag item is encrypted, so values
      # will not be equal if we re-encrypt.
      Chef::EncryptedDataBagItem.should_receive(:encrypt_data_bag_item).and_return(@enc_data)

      @rest.should_receive(:post_rest).with("data", {'name' => 'sudoing_admins'}).ordered
      @rest.should_receive(:post_rest).with("data/sudoing_admins", data_bag_item).ordered

      @secret_file = Tempfile.new("encrypted_data_bag_secret_file_test")
      @secret_file.puts(@secret)
      @secret_file.flush
    end

    after do
      @secret_file.close
      @secret_file.unlink
    end

    it "creates an encrypted data bag item via --secret" do
      @knife.stub!(:config).and_return({:secret => @secret})
      @knife.run
    end

    it "creates an encrypted data bag item via --secret_file" do
      secret_file = Tempfile.new("encrypted_data_bag_secret_file_test")
      secret_file.puts(@secret)
      secret_file.flush
      @knife.stub!(:config).and_return({:secret_file => secret_file.path})
      @knife.run
    end
  end

end
