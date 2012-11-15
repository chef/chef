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

require 'spec_helper'

require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'tempfile'
require 'json'

Chef::Knife::DataBagFromFile.load_deps

describe Chef::Knife::DataBagFromFile do
  before :each do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::DataBagFromFile.new
    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @tmp_dir = Dir.mktmpdir
    @db_folder = File.join(@tmp_dir, 'data_bags', 'bag_name')
    FileUtils.mkdir_p(@db_folder)
    @db_file = Tempfile.new(["data_bag_from_file_test", ".json"], @db_folder)
    @db_file2 = Tempfile.new(["data_bag_from_file_test2", ".json"], @db_folder)
    @db_folder2 = File.join(@tmp_dir, 'data_bags', 'bag_name2')
    FileUtils.mkdir_p(@db_folder2)
    @db_file3 = Tempfile.new(["data_bag_from_file_test3", ".json"], @db_folder2)
    @plain_data = {
        "id" => "item_name",
        "greeting" => "hello",
        "nested" => { "a1" => [1, 2, 3], "a2" => { "b1" => true }}
    }
    @db_file.write(@plain_data.to_json)
    @db_file.flush
    @knife.instance_variable_set(:@name_args, ['bag_name', @db_file.path])
  end

  # We have to explicitly clean up Tempfile on Windows because it said so.
  after :each do
    @db_file.close
    @db_file2.close
    @db_file3.close
    FileUtils.rm_rf(@db_folder)
    FileUtils.rm_rf(@db_folder2)
    FileUtils.remove_entry_secure @tmp_dir
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

  it "loads all from a mutiple files and saves" do
    @knife.name_args = [ 'bag_name', @db_file.path, @db_file2.path ]
    @knife.loader.should_receive(:load_from).with("data_bags", 'bag_name', @db_file.path).and_return(@plain_data)
    @knife.loader.should_receive(:load_from).with("data_bags", 'bag_name', @db_file2.path).and_return(@plain_data)
    dbag = Chef::DataBagItem.new
    Chef::DataBagItem.stub!(:new).and_return(dbag)
    dbag.should_receive(:save).twice
    @knife.run

    dbag.data_bag.should == 'bag_name'
    dbag.raw_data.should == @plain_data
  end

  it "loads all from a folder and saves" do
    dir = File.dirname(@db_file.path)
    @knife.name_args = [ 'bag_name', @db_folder ]
    @knife.loader.should_receive(:load_from).with("data_bags", 'bag_name', @db_file.path).and_return(@plain_data)
    @knife.loader.should_receive(:load_from).with("data_bags", 'bag_name', @db_file2.path).and_return(@plain_data)
    dbag = Chef::DataBagItem.new
    Chef::DataBagItem.stub!(:new).and_return(dbag)
    dbag.should_receive(:save).twice
    @knife.run
  end

  describe "loading all data bags" do

    before do
      @pwd = Dir.pwd
      Dir.chdir(@tmp_dir)
    end

    after do
      Dir.chdir(@pwd)
    end

    it "loads all data bags when -a or --all options is provided" do
      @knife.name_args = []
      @knife.stub!(:config).and_return({:all => true})
      @knife.loader.should_receive(:load_from).with("data_bags", "bag_name", File.basename(@db_file.path)).
        and_return(@plain_data)
      @knife.loader.should_receive(:load_from).with("data_bags", "bag_name", File.basename(@db_file2.path)).
        and_return(@plain_data)
      @knife.loader.should_receive(:load_from).with("data_bags", "bag_name2", File.basename(@db_file3.path)).
        and_return(@plain_data)
      dbag = Chef::DataBagItem.new
      Chef::DataBagItem.stub!(:new).and_return(dbag)
      dbag.should_receive(:save).exactly(3).times
      @knife.run
    end

    it "loads all data bags items when -a or --all options is provided" do
      @knife.name_args = ["bag_name2"]
      @knife.stub!(:config).and_return({:all => true})
      @knife.loader.should_receive(:load_from).with("data_bags", "bag_name2", File.basename(@db_file3.path)).
        and_return(@plain_data)
      dbag = Chef::DataBagItem.new
      Chef::DataBagItem.stub!(:new).and_return(dbag)
      dbag.should_receive(:save)
      @knife.run
      dbag.data_bag.should == 'bag_name2'
      dbag.raw_data.should == @plain_data
    end

  end

  describe "encrypted data bag items" do
    before(:each) do
      @secret = "abc123SECRET"
      @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                   @secret)

      # Random IV is used each time the data bag item is encrypted, so values
      # will not be equal if we re-encrypt.
      Chef::EncryptedDataBagItem.should_receive(:encrypt_data_bag_item).and_return(@enc_data)

      @secret_file = Tempfile.new("encrypted_data_bag_secret_file_test")
      @secret_file.puts(@secret)
      @secret_file.flush
    end

    after do
      @secret_file.close
      @secret_file.unlink
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
      @knife.stub!(:config).and_return({:secret_file => @secret_file.path})

      @knife.loader.stub!(:load_from).with("data_bags", 'bag_name', @db_file.path).and_return(@plain_data)
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
      help_text = "knife data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)"
      help_text_regex = Regexp.new("^#{Regexp.escape(help_text)}")
      @stdout.string.should match(help_text_regex)
    end
  end

end
