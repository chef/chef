#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'tempfile'
require 'json'

Chef::Knife::DataBagFromFile.load_deps

describe Chef::Knife::DataBagFromFile do
  before do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::DataBagFromFile.new
    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @db_file = Tempfile.new(["data_bag_from_file_test", ".json"])
    @plain_data = {
        "id" => "item_name",
        "greeting" => "hello",
        "nested" => { "a1" => [1, 2, 3], "a2" => { "b1" => true }}
    }
    @db_file.write(@plain_data.to_json)
    @db_file.flush
    @knife.instance_variable_set(:@name_args, ['bag_name', @db_file.path])
  end

  it "loads from a file and saves" do
    @knife.loader.should_receive(:load_from).with("data_bags", 'bag_name', @db_file.path).and_return(@plain_data)
    dbag = Chef::DataBagItem.new
    Chef::DataBagItem.stub!(:new).and_return(dbag)
    dbag.should_receive(:save)
    @knife.run

    dbag.data_bag.should == 'bag_name'
    dbag.raw_data.should == @plain_data
  end

  describe "encrypted data bag items" do
    before(:each) do
      @secret = "abc123SECRET"
      @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                   @secret)
    end

    it "encrypts values when given --secret" do
      @knife.stub!(:config).and_return({:secret => @secret})

      @knife.loader.should_receive(:load_from).with("data_bags", "bag_name", @db_file.path).and_return(@plain_data)
      dbag = Chef::DataBagItem.new
      Chef::DataBagItem.stub!(:new).and_return(dbag)
      dbag.should_receive(:save)
      @knife.run
      dbag.data_bag.should == 'bag_name'
      dbag.raw_data.should == @enc_data
    end

    it "encrypts values when given --secret_file" do
      secret_file = Tempfile.new("encrypted_data_bag_secret_file_test")
      secret_file.puts(@secret)
      secret_file.flush
      @knife.stub!(:config).and_return({:secret_file => secret_file.path})

      @knife.stub!(:load_from_file).with(Chef::DataBagItem, @db_file.path,
                                         'bag_name').and_return(@plain_data)
      dbag = Chef::DataBagItem.new
      Chef::DataBagItem.stub!(:new).and_return(dbag)
      dbag.should_receive(:save)
      @knife.run
      dbag.data_bag.should == 'bag_name'
      dbag.raw_data.should == @enc_data
    end

  end

  describe "command line parsing" do
    it "prints help if given no arguments" do
      @knife.instance_variable_set(:@name_args, [])
      lambda { @knife.run }.should raise_error(SystemExit)
      @stdout.string.should match(/^knife data bag from file BAG FILE \(options\)/)
    end
  end

end
